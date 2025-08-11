import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mutex/mutex.dart';
import 'package:near_drop/transport/data/dto/ReceivedFileDTO.dart';
import 'package:near_drop/transport/data/dto/SendRequestDTO.dart';
import 'package:near_drop/transport/data/messages/CancelAck.dart';
import 'package:near_drop/transport/data/messages/CancelMessage.dart';
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

enum ReceiveState
{
    waitingForRequest,
    waitingForFileInfoOrFinish,
    receivingFile,
    finished
}

enum ReceiveResult
{
    ok,
    declined,
    fileWriteError,
    userCanceled,
    connectionError,
}

/// Verarbeitet eingehende Dateien über einen WebRTC-Datenkanal.
class Receiver
{
    static const Duration _progressInterval = Duration(milliseconds: 250);
    static const Duration _cancelTimeoutDuration = Duration(seconds: 8);
    static late final Directory _filesDirectory;

    final RTCDataChannel _dataChannel;
    final RTCDataChannel _controlChannel;
    final Mutex _writeMutex = Mutex();
    Timer? _progressTimer;
    int startTime = 0;
    ReceiveState _receiveState = ReceiveState.waitingForRequest;

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

    final _cancelAckCompleter = Completer<void>();

    late final Function(ReceivedFileDTO file) _onFileReceived;
    late final Function(double progress) _onProgress;
    late final Function(SendRequestDTO sendRequest) _onSendRequest;

    Receiver(this._dataChannel, this._controlChannel)
    {
        //_dataChannel.bufferedAmountLowThreshold = 2 * 1024 * 1024; // 6 MB
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
                if (_receiveState != ReceiveState.waitingForRequest) return;
                dprint("Empfänger: TransferRequestMessage empfangen.");
                _totalSize = controlMessage.totalSize;
                _onSendRequest(SendRequestDTO(controlMessage.filesCount, controlMessage.totalSize, controlMessage.mimeTypeGroup));
                break;
            case FileInfoMessage():
                if (_receiveState != ReceiveState.waitingForFileInfoOrFinish) return;
                dprint("Empfänger: FileInfoMessage empfangen: ${controlMessage.name}, Größe: ${controlMessage.size}");
                await _handleFileInfoMessage(controlMessage);
                break;
            case TransferFinishedMessage():
                if (_receiveState != ReceiveState.waitingForFileInfoOrFinish) return;
                _receiveState = ReceiveState.finished;
                int endTime = DateTime.now().millisecondsSinceEpoch;
                dprint("Empfänger: TransferFinishedMessage empfangen. Dauer: ${(endTime - startTime) / 1000} Sekunden");
                if (!_completer.isCompleted) _completer.complete(ReceiveResult.ok);
                break;
            case CancelMessage():
                dprint("Sender möchte das Senden abbrechen.");
                _receiveState = ReceiveState.finished;
                await _sendCancelAck();
                if (!_completer.isCompleted) _completer.complete(ReceiveResult.userCanceled);
                break;
            case CancelAck():
                dprint("Empfänger: CancelAck empfangen.");
                _cancelAckCompleter.complete();
                break;
            default:
                // Unbekannter Steuerbefehl, ignorieren
                dprint("Unbekannter Steuerbefehl empfangen: ${controlMessage.runtimeType}");
                return;
        }
    }

    /// Sendet eine Bestätigung, dass der Abbruch des Transfers empfangen wurde.
    Future<void> _sendCancelAck() async
    {
        final cancelAckMessage = CancelAck();
        try
        {
            await _controlChannel.send(RTCDataChannelMessage(jsonEncode(cancelAckMessage.toMap())));
            await Future.delayed(Duration(seconds: 1)); // Kurze Verzögerung, um sicherzustellen, dass die Nachricht gesendet wurde
            dprint("Empfänger: CancelAck gesendet.");
        }
        catch (e)
        {
            dprint("Fehler beim Senden des CancelAck: $e");
        }
    }

    /// Verarbeitet einen eingehenden Daten-Chunk.
    Future<void> _handleDataChunk(RTCDataChannelMessage message) async
    {
        if (_receiveState != ReceiveState.receivingFile) return;
        if (!message.isBinary) return;

        dprint("Empfänger: Datenchunk empfangen. Größe: ${message.binary.length} Bytes");
        final chunk = message.binary;
        await _writeMutex.acquire();

        try
        {
            await _currentRaf?.writeFrom(chunk);
            _currentFileBytes += chunk.length;
            _totalReceivedBytes += chunk.length;

            // Prüfen, ob die Datei vollständig empfangen wurde
            if (_currentFileBytes >= _currentFileSize)
            {
                final dto = ReceivedFileDTO(_currentFileName, _currentFilePath, _currentFileSize, _currentMimeType);
                _onFileReceived(dto);
                _resetCurrentFile();

                // Bestätigungsnachricht senden
                dprint("Empfänger: Sende FileReceivedMessage.");
                final receivedMessage = FileReceivedMessage();
                await _controlChannel.send(RTCDataChannelMessage(jsonEncode(receivedMessage.toMap())));
            }
        }
        catch (e)
        {
            dprint("Fehler beim Schreiben der Datei: $e");
            if (!_completer.isCompleted) _completer.complete(ReceiveResult.fileWriteError);
            return;
        }
        finally
        {
            _writeMutex.release();
        }
    }

    /// Setzt den Zustand der aktuellen Datei zurück.
    void _resetCurrentFile()
    {
        _currentFileName = "";
        _currentFilePath = "";
        _currentFileSize = 0;
        _currentFileBytes = 0;
        _currentMimeType = "";
        _receiveState = ReceiveState.waitingForFileInfoOrFinish;
        _currentRaf?.close();
        _currentRaf = null;
    }

    /// Verarbeitet eine eingehende FileInfoMessage, die Informationen über die zu empfangende Datei enthält.
    Future<void> _handleFileInfoMessage(FileInfoMessage message) async
    {
        _currentFileName = message.name;
        _currentFileSize = message.size;
        _currentMimeType = message.mimeType;
        _currentFileBytes = 0;

        try
        {
            final file = await _createFile(_filesDirectory, _currentFileName);
            _currentFilePath = file.path;
            _currentRaf = await file.open(mode: FileMode.writeOnly);
        }
        catch (e)
        {
            dprint("Fehler beim Erstellen der zu empfangenen Datei: $e");
            if (!_completer.isCompleted) _completer.complete(ReceiveResult.fileWriteError);
            return;
        }

        // Senden, dass wir bereit sind, die Datei zu empfangen
        _receiveState = ReceiveState.receivingFile;
        final readyMessage = FileReadyMessage();
        try
        {
            await _controlChannel.send(RTCDataChannelMessage(jsonEncode(readyMessage.toMap())));
        }
        catch (e)
        {
            dprint("Fehler beim Senden der FileReadyMessage: $e");
            if (!_completer.isCompleted) _completer.complete(ReceiveResult.connectionError);
        }
    }

    /// Sendet dem Sender, dass wir den Transfer akzeptieren.
    Future<void> sendAccept() async
    {
        if (_receiveState != ReceiveState.waitingForRequest || _controlChannel.state != RTCDataChannelState.RTCDataChannelOpen)
        {
            return;
        }

        dprint("Empfänger: Sende TransferAcceptMessage.");
        _receiveState = ReceiveState.waitingForFileInfoOrFinish;
        final acceptMessage = TransferAcceptMessage();

        try
        {
            await _controlChannel.send(RTCDataChannelMessage(jsonEncode(acceptMessage.toMap())));
        }
        catch (e)
        {
            dprint("Fehler beim Senden der Transfer-Akzeptanz: $e");
            if (!_completer.isCompleted) _completer.complete(ReceiveResult.connectionError);
            return;
        }

        startTime = DateTime.now().millisecondsSinceEpoch;
        _startProgressReporting();
    }

    /// Sendet dem Senderr, dass wir den Transfer ablehnen.
    Future<void> sendDecline() async
    {
        if (_receiveState != ReceiveState.waitingForRequest || _controlChannel.state != RTCDataChannelState.RTCDataChannelOpen)
        {
            return;
        }

        dprint("Empfänger: Sende TransferDeclineMessage.");
        _receiveState = ReceiveState.finished;
        final declineMessage = TransferDeclineMessage();

        try
        {
            await _controlChannel.send(RTCDataChannelMessage(jsonEncode(declineMessage.toMap())));
        }
        catch (e)
        {
            dprint("Fehler beim Senden der Transfer-Ablehnung: $e");
        }
    }

    /// Sendet dem Sender, dass wir als Empfänger die Übertragung abbrechen möchten.
    Future<void> sendCancel() async
    {
        _receiveState = ReceiveState.finished;
        final cancelMessage = CancelMessage();

        try
        {
            await _controlChannel.send(RTCDataChannelMessage(jsonEncode(cancelMessage.toMap())));
            await _cancelAckCompleter.future.timeout(_cancelTimeoutDuration, onTimeout: () {
                dprint("Empfänger: Timeout beim Warten auf CancelAck.");
            });
        }
        catch (e)
        {
            dprint("Fehler beim Senden des Abbrechen-Flags: $e");
        }
    }

    /// Startet einen Timer, der regelmäßig den Fortschritt der Dateiübertragung meldet.
    void _startProgressReporting()
    {
        _progressTimer?.cancel();
        _progressTimer = Timer.periodic(_progressInterval, (timer) async
        {
            // Wenn die Übertragung beendet wurde, den Timer stoppen
            if (_receiveState == ReceiveState.finished || _dataChannel.state != RTCDataChannelState.RTCDataChannelOpen)
            {
                _receiveState = ReceiveState.finished; // Sicherheitshalbar
                timer.cancel();
                return;
            }

            if (_totalSize == 0) return;
            double progress = _totalReceivedBytes / _totalSize;

            // Sender über den Fortschritt informieren
            final progressMessage = ProgressMessage(progress);
            await _controlChannel.send(RTCDataChannelMessage(jsonEncode(progressMessage.toMap())));
            _onProgress(progress); // Callback aufrufen, um Fortschritt an UI zu melden
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

    /// Löscht die Datei, in die aktuell geschrieben wird.
    /// Notwendig, wenn während der Übertragung ein Fehler auftritt.
    Future<void> deleteCurrentBrokenFile() async
    {
        if (_currentFilePath.isEmpty) return;

        try
        {
            _currentRaf?.close();
        }
        catch (e)
        {
            // Ignorieren
        }

        try
        {
            File(_currentFilePath).delete();
        }
        catch (e)
        {
            // Ignorieren
        }
    }

    void dispose()
    {
        _receiveState = ReceiveState.finished;
        _progressTimer?.cancel();
        if (!_completer.isCompleted) _completer.complete(ReceiveResult.userCanceled);
        _resetCurrentFile();
    }
}