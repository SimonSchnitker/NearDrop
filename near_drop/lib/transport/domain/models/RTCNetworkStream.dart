import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mutex/mutex.dart';

/// Umschließt einen RTCDataChannel und stellt Methoden bereit, um Daten zu senden und zu empfangen.
class RTCNetworkStream
{
    final RTCDataChannel _dataChannel;
    final Queue<String> _stringQueue = Queue<String>();
    final Queue<Uint8List> _binaryQueue = Queue<Uint8List>();
    final StreamController<String> _stringStreamController = StreamController<String>.broadcast();
    final StreamController<Uint8List> _binaryStreamController = StreamController<Uint8List>.broadcast();
    final _stringStreamMutex = Mutex();
    final _binaryStreamMutex = Mutex();

    RTCNetworkStream(this._dataChannel)
    {
        _dataChannel.onMessage = _onMessage;
    }

    /// Behandelt eingehende Nachrichten vom RTCDataChannel.
    Future<void> _onMessage(RTCDataChannelMessage message) async
    {
        if (message.isBinary)
        {
            await _binaryStreamMutex.protect(() async
            {
                if (_binaryStreamController.hasListener)
                {
                    _binaryStreamController.add(message.binary);
                }
                else
                {
                    _binaryQueue.add(message.binary);
                }
            });
        }
        else
        {
            await _stringStreamMutex.protect(() async
            {
                if (_stringStreamController.hasListener)
                {
                    _stringStreamController.add(message.text);
                }
                else
                {
                    _stringQueue.add(message.text);
                }
            });
        }
    }

    /// Liest einen String asynchron vom Stream.
    Future<String> readString() async
    {
        Completer<String> completer = Completer<String>();
        StreamSubscription? subscription;

        await _stringStreamMutex.protect(() async
        {
            if (_stringQueue.isNotEmpty)
            {
                return _stringQueue.removeFirst();
            }

            subscription = _stringStreamController.stream.listen((text)
            {
                completer.complete(text);
                subscription?.cancel();
            });
        });

        return await completer.future;

        //return await _stringStreamController.stream.first;
    }

    /// Liest Binärdaten (Uint8List) asynchron vom Stream.
    Future<Uint8List> readBinary() async
    {
        Completer<Uint8List> completer = Completer<Uint8List>();
        StreamSubscription? subscription;

        await _binaryStreamMutex.protect(() async
        {
            if (_binaryQueue.isNotEmpty)
            {
                return _binaryQueue.removeFirst();
            }

            subscription = _binaryStreamController.stream.listen((data)
            {
                completer.complete(data);
                subscription?.cancel();
            });
        });

        return await completer.future;

        //return await _binaryStreamController.stream.first;
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