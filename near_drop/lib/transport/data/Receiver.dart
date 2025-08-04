import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mutex/mutex.dart';
import 'package:near_drop/transport/data/dto/ReceivedFileDTO.dart';
import 'package:near_drop/transport/data/dto/SendRequestDTO.dart';
import 'package:near_drop/transport/data/messages/FileInfoMessage.dart';
import 'package:near_drop/transport/data/messages/FileReadyMessage.dart';
import 'package:near_drop/transport/data/messages/FileReceivedMessage.dart';
import 'package:near_drop/transport/data/messages/ProgressMessage.dart';
import 'package:near_drop/transport/data/messages/TransferAcceptMessage.dart';
import 'package:near_drop/transport/data/messages/TransferDeclineMessage.dart';
import 'package:near_drop/transport/data/messages/TransferFinishedMessage.dart';
import 'package:near_drop/transport/data/messages/TransferRequestMessage.dart';
import 'package:path/path.dart';
import '../../main.dart';
import 'messages/ControlMessage.dart';

enum ReceiveResult
{
    ok,
    declined,
    fileWriteError,
    unknownError,
}

/// Verarbeitet eingehende Dateien über einen WebRTC-Datenkanal.
class Receiver
{
    final RTCDataChannel _dataChannel;
    final RTCDataChannel _controlChannel;
    static late final Directory _filesDirectory;
    final Mutex _writeMutex = Mutex();
    Timer? _progressTimer;
    static const Duration _progressInterval = Duration(milliseconds: 250);
    int startTime = 0;

    String _currentFileName = "";
    String _currentFilePath = "";
    int _currentFileSize = 0;
    String _currentMimeType = "";
    RandomAccessFile? _currentRaf;
    int _currentFileBytes = 0;
    int _totalReceivedBytes = 0;
    int _totalSize = 0;

    // Die Completer, der aufgelöst wird, wenn die Verbindung steht (oder fehlschlägt)
    final _completer = Completer<ReceiveResult>();
    Future<ReceiveResult> get isFinished => _completer.future;

    // Callback, der für jede fertige Datei aufgerufen wird
    late final Function(ReceivedFileDTO file) _onFileReceived;
    late final Function(double progress) _onProgress;
    late final Function(SendRequestDTO sendRequest) _onSendRequest;

    Receiver(this._dataChannel, this._controlChannel)
    {
        _dataChannel.bufferedAmountLowThreshold = 2 * 1024 * 1024; // 6 MB
        _dataChannel.onMessage = _handleDataChunk;
        _controlChannel.onMessage = _handleControlMessage;
    }

    /// Setzt den Ordner in dem empfangene Dateien gespeichert werden.
    static void setFilesDirectory(Directory directory)
    {
        _filesDirectory = directory;
    }

    /// Registiert Callback-Funktionen, die während des Empfangs aufgerufen werden.
    void listen(Function(SendRequestDTO) onSendRequest, Function(ReceivedFileDTO) onFileReceived, Function(double) onProgress)
    {
        _onSendRequest = onSendRequest;
        _onFileReceived = onFileReceived;
        _onProgress = onProgress;
    }

    /// Verarbeitet eingehende Steuerbefehle.
    Future<void> _handleControlMessage(RTCDataChannelMessage message) async
    {
        if (message.isBinary) return; // Nur Textnachrichten verarbeiten
        final controlMessage = ControlMessage.fromMap(jsonDecode(message.text));

        switch (controlMessage)
        {
            case TransferRequestMessage():
                dprint("Empfänger: TransferRequestMessage empfangen.");
                _totalSize = controlMessage.totalSize;
                _onSendRequest(SendRequestDTO(controlMessage.filesCount, controlMessage.totalSize, controlMessage.mimeTypeGroup));
                break;
            case FileInfoMessage():
                dprint("Empfänger: FileInfoMessage empfangen: ${controlMessage.name}, Größe: ${controlMessage.size}");
                _handleFileInfoMessage(controlMessage);
                break;
            case TransferFinishedMessage():
                int endTime = DateTime.now().millisecondsSinceEpoch;
                dprint("Empfänger: TransferFinishedMessage empfangen. Dauer: ${(endTime - startTime) / 1000} Sekunden");
                _completer.complete(ReceiveResult.ok);
            default:
                // Unbekannter Steuerbefehl, ignorieren
                dprint("Unbekannter Steuerbefehl empfangen: ${controlMessage.runtimeType}");
                return;
        }
    }

    /// Verarbeitet einen eingehenden Daten-Chunk.
    Future<void> _handleDataChunk(RTCDataChannelMessage message) async
    {
        if (!message.isBinary) return;

        dprint("Empfänger: Datenchunk empfangen. Größe: ${message.binary.length} Bytes");
        final chunk = message.binary;
        await _writeMutex.acquire();

        try
        {
            await _currentRaf?.writeFrom(chunk);
            _currentFileBytes += chunk.length;
            _totalReceivedBytes += chunk.length;
        }
        catch (e)
        {
            dprint("Fehler beim Schreiben der Datei: $e");
            _completer.complete(ReceiveResult.fileWriteError);
            return;
        }
        finally
        {
            _writeMutex.release();
        }

        // Prüfen, ob die Datei vollständig empfangen wurde
        if (_currentFileBytes >= _currentFileSize)
        {
            await _writeMutex.acquire();
            try
            {
                final dto = ReceivedFileDTO(_currentFileName, _currentFilePath, _currentFileSize, _currentMimeType);
                _onFileReceived(dto);

                // Zustand zurücksetzen
                _currentFileName = "";
                _currentFilePath = "";
                _currentFileSize = 0;
                _currentFileBytes = 0;
                _currentMimeType = "";
                _currentRaf?.close();
                _currentRaf = null;

                // Bestätigungsnachricht senden
                dprint("Empfänger: Sende FileReceivedMessage.");
                final receivedMessage = FileReceivedMessage();
                await _controlChannel.send(RTCDataChannelMessage(jsonEncode(receivedMessage.toMap())));
            }
            catch (e)
            {
                dprint("Fehler beim Verarbeiten der empfangenen Datei: $e");
                _completer.complete(ReceiveResult.unknownError);
                return;
            }
            finally
            {
                _writeMutex.release();
            }
        }
    }

    /// Verarbeitet eine eingehende FileInfoMessage, die Informationen über die zu empfangende Datei enthält.
    Future<void> _handleFileInfoMessage(FileInfoMessage message) async
    {
        try
        {
            _currentFileName = message.name;
            _currentFileSize = message.size;
            _currentMimeType = message.mimeType;
            _currentFileBytes = 0;

            // Datei im Zielordner erstellen
            final file = await _createFile(_filesDirectory, _currentFileName);
            _currentFilePath = file.path;
            _currentRaf = await file.open(mode: FileMode.writeOnly);

            // Senden, dass wir bereit sind, die Datei zu empfangen
            final readyMessage = FileReadyMessage();
            await _controlChannel.send(RTCDataChannelMessage(jsonEncode(readyMessage.toMap())));
        }
        catch (e)
        {
            dprint("Fehler beim Verarbeiten der FileInfoMessage: $e");
            _completer.complete(ReceiveResult.unknownError);
        }
    }

    /// Sendet dem Sender, dass wir den Transfer akzeptieren.
    Future<void> sendAccept() async
    {
        try
        {
            dprint("Empfänger: Sende TransferAcceptMessage.");
            final acceptMessage = TransferAcceptMessage();
            await _controlChannel.send(RTCDataChannelMessage(jsonEncode(acceptMessage.toMap())));
            startTime = DateTime.now().millisecondsSinceEpoch;
            _startProgressReporting();
        }
        catch (e)
        {
            dprint("Fehler beim Senden der Transfer-Akzeptanz: $e");
            _completer.complete(ReceiveResult.unknownError);
            return;
        }
    }

    /// Sendet dem Senderr, dass wir den Transfer ablehnen.
    Future<void> sendDecline() async
    {
        try
        {
            dprint("Empfänger: Sende TransferDeclineMessage.");
            final declineMessage = TransferDeclineMessage();
            return _controlChannel.send(RTCDataChannelMessage(jsonEncode(declineMessage.toMap())));
        }
        catch (e)
        {
            dprint("Fehler beim Senden der Transfer-Ablehnung: $e");
            _completer.complete(ReceiveResult.unknownError);
        }
    }

    /// Startet einen Timer, der regelmäßig den Fortschritt der Dateiübertragung meldet.
    void _startProgressReporting()
    {
        _progressTimer?.cancel();
        _progressTimer = Timer.periodic(_progressInterval, (timer) async
        {
            if (_totalSize == 0) return;
            double progress = _totalReceivedBytes / _totalSize;

            // Sender über den Fortschritt informieren
            final progressMessage = ProgressMessage(progress);
            await _controlChannel.send(RTCDataChannelMessage(jsonEncode(progressMessage.toMap())));
            _onProgress(progress); // Callback aufrufen, um Fortschritt an UI zu melden

            // Wenn die Übertragung fertig ist, den Timer stoppen
            if (_totalReceivedBytes >= _totalSize)
            {
                timer.cancel();
            }
        });
    }

    /// Erstellt eine Datei im angegebenen Ordner mit dem angegebenen Dateinamen.
    Future<File> _createFile(Directory directory, String filename) async
    {
        String ext = extension(filename);
        String filenameWithoutExt = basenameWithoutExtension(filename);
        File file = File(join(directory.path, filename));

        // Zahl hinter dem Dateinamen erhöhen, falls Datei bereits existiert
        int i = 1;
        while (await file.exists())
        {
            file = File(join(directory.path, "$filenameWithoutExt ($i)$ext"));
            i++;
        }

        return file;
    }

    void dispose()
    {
        _progressTimer?.cancel();
    }
}