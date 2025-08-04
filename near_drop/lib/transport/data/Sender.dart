import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mime/mime.dart';
import 'package:near_drop/transport/data/messages/ControlMessage.dart';
import 'package:near_drop/transport/data/messages/FileInfoMessage.dart';
import 'package:near_drop/transport/data/messages/FileReadyMessage.dart';
import 'package:near_drop/transport/data/messages/ProgressMessage.dart';
import 'package:near_drop/transport/data/messages/TransferRequestMessage.dart';
import 'package:near_drop/transport/domain/enums/MimeTypeGroup.dart';
import 'package:path/path.dart';
import '../../main.dart';
import 'messages/FileReceivedMessage.dart';
import 'messages/TransferAcceptMessage.dart';
import 'messages/TransferDeclineMessage.dart';
import 'messages/TransferFinishedMessage.dart';

enum SendResult
{
    ok,
    receiverDeclined,
    timeout,
    unkownError,
}

/// Verarbeitet den Sendevorgang von Dateien über einen RTCDataChannel.
class Sender
{
    static const int _chunkSize = 64 * 1024; // 64 KB: Größe eines einzelnen Chunks
    static const int _bufferedAmountThreshold = 128 * 1024; // 128 KB: Schwellenwert, ab dem der Puffer wieder Platz hat
    static const int _highWaterMark = 128 * 1024; // 128 KB: Senden stoppen
    static const int _lowWaterMark = 64 * 1024;  // 64 KB: Senden fortsetzen
    static const int _chunkBatchSize = 1; // Sende 1 Chunk (64 KB) am Stück, bevor der Puffer überprüft wird

    final RTCDataChannel _dataChannel;
    final RTCDataChannel _controlChannel;

    // Stream für eingehende Kontrollnachrichten
    final _controlStreamController = StreamController<ControlMessage>.broadcast();
    Stream<ControlMessage> get _controlStream => _controlStreamController.stream;

    // Completer für das Event, wenn der Puffer wieder Platz hat
    Completer<void>? _lowAmountCompleter;

    Sender(this._dataChannel, this._controlChannel)
    {
        _dataChannel.bufferedAmountLowThreshold = _bufferedAmountThreshold;
        _controlChannel.onMessage = (message)
        {
            if (message.isBinary) return; // Nur Textnachrichten verarbeiten
            _controlStreamController.add(ControlMessage.fromMap(jsonDecode(message.text)));
        };

        return;
        // Nur unter Android verfügbar
        if (Platform.isAndroid)
        {
            _dataChannel.onBufferedAmountChange = (amount, a) {
                // Wird aufgerufen, wenn sich der Puffer ändert
                dprint("Sender: Buffered Amount geändert: $amount, $a Bytes");
            };

            // Wird aufgerufen, wenn der Puffer des DataChannels vorher voll war und jetzt wieder Platz hat
            _dataChannel.onBufferedAmountLow = (amount) {
                if (_lowAmountCompleter != null && !_lowAmountCompleter!.isCompleted && amount < _lowWaterMark)
                {
                    dprint("✅ Event: Puffer hat wieder Platz. Setze Übertragung fort.");
                    _lowAmountCompleter!.complete();
                }
            };
        }
    }

    /// Startet den gesamten Sendevorgang.
    Future<SendResult> start(List<File> files, int totalSize, MimeTypeGroup mimeTypeGroup, Function(double progress) onProgress) async
    {
        // 1. Handshake: Transfer anfragen
        dprint("Sender: TransferRequestMessage senden");
        final request = TransferRequestMessage(files.length, totalSize, mimeTypeGroup);
        await _controlChannel.send(RTCDataChannelMessage(jsonEncode(request.toMap())));

        try
        {
            // Auf Antwort vom Empfänger warten: Akzeptieren oder Ablehnen
            dprint("Sender: Warte auf TransferAcceptMessage oder TransferDeclineMessage...");
            final response = await _controlStream.firstWhere((msg) => msg is TransferAcceptMessage || msg is TransferDeclineMessage,
            ).timeout(const Duration(seconds: 30));

            if (response is TransferDeclineMessage)
            {
                dprint("Sender: Transfer abgelehnt vom Empfänger.");
                return SendResult.receiverDeclined;
            }
        }
        on TimeoutException
        {
            return SendResult.timeout;
        }

        dprint("Sender: Transfer akzeptiert. Starte Dateiübertragung...");

        // Auf asynchrone Progress-Updates vom Empfänger lauschen
        _controlStream.where((msg) => msg is ProgressMessage).listen((msg)
        {
            onProgress((msg as ProgressMessage).progress);
        });

        // 2. Datei-Loop: Metadaten und Chunks senden
        int start = DateTime.now().millisecondsSinceEpoch;
        for (final file in files)
        {
            dprint("Sender: Sende FileInfoMessage für Datei ${file.path}...");
            final fileInfo = FileInfoMessage(basename(file.path), await file.length(), lookupMimeType(file.path) ?? "");
            await _controlChannel.send(RTCDataChannelMessage(jsonEncode(fileInfo.toMap())));

            try
            {
                // Warten auf Bestätigung, dass der Empfänger bereit für die Datei ist
                dprint("Sender: Warte auf FileReadyMessage für Datei ${file.path}...");
                await _controlStream.firstWhere((msg) => msg is FileReadyMessage).timeout(const Duration(seconds: 15));
            }
            on TimeoutException
            {
                return SendResult.timeout;
            }

            // Chunks senden
            final raf = await file.open(mode: FileMode.read);
            final fileSize = await raf.length();
            int bytesSent = 0;
            while (bytesSent < fileSize)
            {
                /*
                if (Platform.isAndroid)
                {
                    // Diese Version funktioniert nur unter Android, da die bufferedAmount-Eigenschaft und die Events auf den anderen Plattformen nicht implementiert sind.
                    if ((_dataChannel.bufferedAmount ?? 0) >= _bufferedAmountThreshold)
                    {
                        dprint("⏸️ Puffer voll. Pausiere und warte auf onBufferedAmountLow Event...");
                        // Erstelle einen neuen Completer für dieses Warte-Ereignis
                        _lowAmountCompleter = Completer<void>();
                        // Warte hier auf das Future des Completers
                        await _lowAmountCompleter!.future;
                    }

                    dprint("Sender: Sende Chunk mit Größe ${_chunkSize} Bytes. Buffered Amount: ${_dataChannel.bufferedAmount} Bytes");
                    final chunk = await raf.read(_chunkSize);
                    await _dataChannel.send(RTCDataChannelMessage.fromBinary(chunk));
                    bytesSent += chunk.length;
                }
                else
                {

                }
                 */

                // 1. Sende einen schnellen "Batch" von Chunks ohne jede Prüfung
                dprint("Sender: Sende Batch von Chunks...");
                for (int i = 0; i < _chunkBatchSize && bytesSent < fileSize; i++)
                {
                    final chunk = await raf.read(_chunkSize);
                    if (chunk.isEmpty) break;

                    await _dataChannel.send(RTCDataChannelMessage.fromBinary(chunk));
                    bytesSent += chunk.length;
                }

                // Prüfe den Pufferstand nach dem Senden des Batches
                int currentBufferedAmount = await _dataChannel.getBufferedAmount();
                dprint("Sender: Aktueller Pufferstand: $currentBufferedAmount Bytes");

                // 2. WENN der obere Schwellenwert überschritten ist...
                if (currentBufferedAmount >= _highWaterMark)
                {
                    dprint("Puffer über Schwellenwert. Warte, bis er unter $_lowWaterMark Bytes fällt...");

                    // 3. ...DANN warte so lange, bis er den UNTEREN Schwellenwert unterschreitet.
                    while (currentBufferedAmount > _lowWaterMark)
                    {
                        await Future.delayed(const Duration(milliseconds: 25));
                        currentBufferedAmount = await _dataChannel.getBufferedAmount();
                        dprint("Aktueller Pufferstand: $currentBufferedAmount Bytes");
                    }
                    dprint("Puffer hat wieder ausreichend Platz. Pufferstand: $currentBufferedAmount Bytes");
                }
            }
            await raf.close();

            int end = DateTime.now().millisecondsSinceEpoch;
            dprint("Sender: Alle Chunks für Datei ${file.path} gesendet. Zeit: ${(end - start) / 1000}s)");

            // Warten auf Bestätigung, dass die Datei empfangen wurde
            dprint("Sender: Warte auf FileReceivedMessage für Datei ${file.path}...");
            await _controlStream.firstWhere((msg) => msg is FileReceivedMessage);
        }

        // 3. Finale Nachricht senden, dass der Transfer abgeschlossen ist
        dprint("Sender: Sende TransferFinishedMessage...");
        final finishedMessage = TransferFinishedMessage();
        await _controlChannel.send(RTCDataChannelMessage(jsonEncode(finishedMessage.toMap())));

        return SendResult.ok;
    }

    void dispose()
    {
        _controlStreamController.close();
    }
}