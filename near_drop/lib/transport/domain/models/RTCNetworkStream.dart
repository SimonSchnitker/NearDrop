import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mutex/mutex.dart';

/// Umschließt einen RTCDataChannel und stellt Methoden bereit, um Daten zu senden und zu empfangen.
class RTCNetworkStream
{
    static const Duration _queueCheckInterval = Duration(milliseconds: 25);

    final RTCDataChannel _dataChannel;
    final Queue<String> _stringQueue = Queue<String>();
    final Queue<Uint8List> _binaryQueue = Queue<Uint8List>();

    RTCNetworkStream(this._dataChannel)
    {
        _dataChannel.onMessage = _onMessage;
    }

    /// Behandelt eingehende Nachrichten vom RTCDataChannel.
    Future<void> _onMessage(RTCDataChannelMessage message) async
    {
        if (message.isBinary)
        {
            _binaryQueue.add(message.binary);
        }
        else
        {
            _stringQueue.add(message.text);
        }
    }

    /// Liest einen String asynchron vom Stream.
    Future<String> readString() async
    {
        // Warten, bis ein String verfügbar ist
        while (_stringQueue.isEmpty)
        {
            await Future.delayed(_queueCheckInterval);

            // Überprüfen, ob der DataChannel geschlossen ist
            if (_dataChannel.state == RTCDataChannelState.RTCDataChannelClosed)
            {
                throw Exception("RTCDataChannel is closed, cannot read string.");
            }
        }

        return _stringQueue.removeFirst();
    }

    /// Liest Binärdaten (Uint8List) asynchron vom Stream.
    Future<Uint8List> readBinary() async
    {
        // Warten, bis Binärdaten verfügbar sind
        while (_binaryQueue.isEmpty)
        {
            await Future.delayed(_queueCheckInterval);

            // Überprüfen, ob der DataChannel geschlossen ist
            if (_dataChannel.state == RTCDataChannelState.RTCDataChannelClosed)
            {
                throw Exception("RTCDataChannel is closed, cannot read binary data.");
            }
        }

        return _binaryQueue.removeFirst();
    }

    /// Schreibt einen String in den RTCDataChannel.
    Future<void> writeString(String message) async
    {
        await _dataChannel.send(RTCDataChannelMessage(message));
    }

    /// Schreibt Binärdaten (Uint8List) in den RTCDataChannel.
    Future<void> writeBinary(Uint8List data) async
    {
        await _dataChannel.send(RTCDataChannelMessage.fromBinary(data));
    }

    /// Schließt den zugrunde liegenden RTCDataChannel.
    Future<void> close() async
    {
        _stringQueue.clear();
        _binaryQueue.clear();
        await _dataChannel?.close();
    }
}