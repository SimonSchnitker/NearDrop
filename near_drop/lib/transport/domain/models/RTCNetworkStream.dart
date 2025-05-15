import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mutex/mutex.dart';

/// Umschließt einen RTCDataChannel und stellt Methoden bereit, um Daten zu senden und zu empfangen.
class RTCNetworkStream
{
    final RTCDataChannel _dataChannel;
    final StreamController<String> _stringStreamController = StreamController<String>.broadcast();
    final StreamController<Uint8List> _binaryStreamController = StreamController<Uint8List>.broadcast();

    RTCNetworkStream(this._dataChannel)
    {
        _dataChannel.onMessage = _onMessage;
    }

    /// Behandelt eingehende Nachrichten vom RTCDataChannel.
    Future<void> _onMessage(RTCDataChannelMessage message) async
    {
        if (message.isBinary)
        {
            while (!_binaryStreamController.hasListener)
            {
                if (_dataChannel.state == RTCDataChannelState.RTCDataChannelClosed)
                {
                    return;
                }

                await Future.delayed(const Duration(milliseconds: 50));
            }

            _binaryStreamController.add(message.binary);
        }
        else
        {
            while (!_stringStreamController.hasListener)
            {
                if (_dataChannel.state == RTCDataChannelState.RTCDataChannelClosed)
                {
                    return;
                }

                await Future.delayed(const Duration(milliseconds: 50));
            }

            _stringStreamController.add(message.text);
        }
    }

    /// Liest einen String asynchron vom Stream.
    Future<String> readString() async
    {
        return await _stringStreamController.stream.first;
    }

    /// Liest Binärdaten (Uint8List) asynchron vom Stream.
    Future<Uint8List> readBinary() async
    {
        return await _binaryStreamController.stream.first;
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
        await _stringStreamController.close();
        await _binaryStreamController.close();
        await _dataChannel?.close();
    }
}