import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mime/mime.dart';
import 'package:near_drop/transport/data/messages/CancelMessage.dart';
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
    timeout,
    userCanceled,
    connectionError,
}

enum RequestResult
{
    accepted,
    declined,
    timeout,
    connectionError
}

/// Verarbeitet den Sendevorgang von Dateien über einen RTCDataChannel.
class Sender
{
    static const Duration _timeoutDuration = Duration(seconds: 30);
    static const int _chunkSize = 64 * 1024; // 64 KB: Größe eines einzelnen Chunks
    static const int _bufferedAmountThreshold = 64 * 1024; // Unter 64 KB: Schwellenwert, ab dem der Puffer wieder Platz hat
    static const int _highWaterMark = 128 * 1024; // Über 128 KB: Senden stoppen
    static const int _lowWaterMark = 64 * 1024;  // Unter 64 KB: Senden fortsetzen

    final RTCDataChannel _dataChannel;
    final RTCDataChannel _controlChannel;
    int startTime = 0;
    bool _isCanceled = false;

    // Stream für eingehende Kontrollnachrichten
    final _controlStreamController = StreamController<ControlMessage>.broadcast();
    Stream<ControlMessage> get _controlStream => _controlStreamController.stream;

    // Die Completer, der aufgelöst wird, wenn das Senden abgeschlossen wurde (oder fehlschlug)
    final _sendCompleter = Completer<SendResult>();
    Future<SendResult> get sendResult => _sendCompleter.future;

    // Die Completer, der aufgelöst wird, wenn das das Anfragen abgeschlossen wurde
    final _requestCompleter = Completer<RequestResult>();
    Future<RequestResult> get requestResult => _requestCompleter.future;

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

    /// Senden eine Anfrage an den Empfänger.
    void request(int filesCount, int totalSize, MimeTypeGroup mimeTypeGroup) async
    {
        // 1. Handshake: Transfer anfragen
        dprint("Sender: TransferRequestMessage senden");
        final request = TransferRequestMessage(filesCount, totalSize, mimeTypeGroup);

        try
        {
            await _controlChannel.send(RTCDataChannelMessage(jsonEncode(request.toMap())));

            // Auf Antwort vom Empfänger warten: Akzeptieren oder Ablehnen
            dprint("Sender: Warte auf TransferAcceptMessage oder TransferDeclineMessage...");
            final response = await _controlStream.firstWhere((msg) => msg is TransferAcceptMessage || msg is TransferDeclineMessage,
            ).timeout(_timeoutDuration);

            if (response is TransferDeclineMessage)
            {
                dprint("Sender: Transfer abgelehnt vom Empfänger.");
                _requestCompleter.complete(RequestResult.declined);
                return;
            }
        }
        on TimeoutException
        {
            _requestCompleter.complete(RequestResult.timeout);
            return;
        }
        catch (e)
        {
            _requestCompleter.complete(RequestResult.connectionError);
            return;
        }

        dprint("Sender: Transfer akzeptiert. Starte Dateiübertragung...");
        _requestCompleter.complete(RequestResult.accepted);
    }

    /// Startet den gesamten Sendevorgang.
    void start(List<File> files, Function(double progress) onProgress) async
    {
        startTime = DateTime.now().millisecondsSinceEpoch;

        // Auf asynchrone Progress-Updates vom Empfänger lauschen
        _controlStream.where((msg) => msg is ProgressMessage).listen((msg)
        {
            onProgress((msg as ProgressMessage).progress);
        });

        // Auf Cancel-Flag vom Empfänger lauschen
        _controlStream.where((msg) => msg is CancelMessage).listen((msg)
        {
            _isCanceled = true;
            _sendCompleter.complete(SendResult.userCanceled);
        });

        // Datei-Loop: Metadaten und Chunks senden
        for (final file in files)
        {
            if (_isCanceled) return; // Regelmäßig nach _isCanceled prüfen

            String filename = basename(file.path);
            int size = await file.length();
            String mimeType = lookupMimeType(file.path) ?? "";

            try
            {
                await _sendFileInfo(filename, size, mimeType);
                await _waitForFileReady();
            }
            on TimeoutException
            {
                _sendCompleter.complete(SendResult.timeout);
                return;
            }
            catch (e)
            {
                _sendCompleter.complete(SendResult.connectionError);
                return;
            }

            try
            {
                await _sendFile(file, size);
                await _waitForFileReceived();
            }
            on TimeoutException
            {
                _sendCompleter.complete(SendResult.timeout);
                return;
            }
            catch (e)
            {
                _sendCompleter.complete(SendResult.connectionError);
                return;
            }
        }

        // Finale Nachricht senden, dass der Transfer abgeschlossen ist
        await _sendFinished();
        _sendCompleter.complete(SendResult.ok);
    }

    /// Sendet dem Empfänger, dass die Übertragung abgeschlossen ist
    Future<void> _sendFinished() async
    {
        dprint("Sender: Sende TransferFinishedMessage...");
        final finishedMessage = TransferFinishedMessage();
        await _controlChannel.send(RTCDataChannelMessage(jsonEncode(finishedMessage.toMap())));

        int endTime = DateTime.now().millisecondsSinceEpoch;
        dprint("Sender: Alle Dateien gesendet. Zeit: ${(endTime - startTime) / 1000}s)");
    }

    /// Sendet Informationen einer Datei an den Empfänger.
    Future<void> _sendFileInfo(String name, int size, String mimeType) async
    {
        dprint("Sender: Sende FileInfoMessage für Datei $name...");
        final fileInfo = FileInfoMessage(name, size, mimeType);
        await _controlChannel.send(RTCDataChannelMessage(jsonEncode(fileInfo.toMap())));
    }

    /// Wartet auf die Nachricht vom Empfänger, dass er bereit ist, eine Datei zu empfangen.
    Future<void> _waitForFileReady() async
    {
        dprint("Sender: Warte auf FileReadyMessage...");
        await _controlStream.firstWhere((msg) => msg is FileReadyMessage).timeout(_timeoutDuration);
    }

    /// Sendet eine Datei an den Empfänger.
    Future<void> _sendFile(File file, int size) async
    {
        final raf = await file.open(mode: FileMode.read);
        int bytesSent = 0;
        while (bytesSent < size)
        {
            if (_isCanceled) return; // Regelmäßig nach _isCanceled prüfen

            // Einen Chunk senden
            dprint("Sende Chunks mit $_chunkSize Bytes.");
            final chunk = await raf.read(_chunkSize);
            if (chunk.isEmpty) break;

            await _dataChannel.send(RTCDataChannelMessage.fromBinary(chunk));
            bytesSent += chunk.length;

            // Prüfe den Pufferstand nach dem Senden des Batches
            int currentBufferedAmount = await _dataChannel.getBufferedAmount();
            dprint("Sender: Aktueller Pufferstand: $currentBufferedAmount Bytes");

            // Wenn der obere Schwellenwert überschritten ist...
            if (currentBufferedAmount > _highWaterMark)
            {
                dprint("Puffer über Schwellenwert. Warte, bis er unter $_lowWaterMark Bytes fällt...");

                // ...dann warte so lange, bis er den UNTEREN Schwellenwert unterschreitet.
                if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
                {
                    _lowAmountCompleter = Completer<void>();
                    await _lowAmountCompleter!.future;
                }
                else
                {
                    while (currentBufferedAmount > _lowWaterMark)
                    {
                        if (_isCanceled) return; // Regelmäßig nach _isCanceled prüfen

                        await Future.delayed(const Duration(milliseconds: 25));
                        currentBufferedAmount = await _dataChannel.getBufferedAmount();
                        dprint("Aktueller Pufferstand: $currentBufferedAmount Bytes");
                    }
                }

                dprint("Puffer hat wieder ausreichend Platz. Pufferstand: $currentBufferedAmount Bytes");
            }
        }

        await raf.close();
    }

    /// Wartet auf die Nachricht vom Empfänger, dass er eine Datei empfangen hat.
    Future<void> _waitForFileReceived() async
    {
        // Warten auf Bestätigung, dass die Datei empfangen wurde
        dprint("Sender: Warte auf FileReceivedMessage...");
        await _controlStream.firstWhere((msg) => msg is FileReceivedMessage).timeout(_timeoutDuration);
    }

    /// Sendet dem Empfänger, dass wir als Sender die Übertragung abbrechen möchten.
    Future<void> sendCancel() async
    {
        _isCanceled = true;
        final cancelMessage = CancelMessage();

        try
        {
            await _controlChannel.send(RTCDataChannelMessage(jsonEncode(cancelMessage.toMap())));
        }
        catch (e)
        {
            dprint("Fehler beim Senden des Abbrechen-Flags: $e");
        }

        _requestCompleter.complete(RequestResult.declined);
        _sendCompleter.complete(SendResult.userCanceled);
    }

    void dispose()
    {
        _isCanceled = true;
        _controlStreamController.close();
    }
}