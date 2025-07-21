import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mutex/mutex.dart';

/// Umschließt einen RTCDataChannel und stellt Methoden bereit, um Daten zu senden und zu empfangen.
/// Diese Version ist mit Mutexes gegen Race Conditions abgesichert.
class RTCNetworkStream
{
    // Mutex für den String- und Binär-Pfad.
    // Werden als Instanzvariablen deklariert, damit sich verschiedene
    // RTCNetworkStream-Instanzen nicht gegenseitig blockieren.
    final Mutex _stringMutex = Mutex();
    final Mutex _binaryMutex = Mutex();

    final RTCDataChannel _dataChannel;
    final StreamController<String> _stringStream = StreamController<String>.broadcast();
    final StreamController<Uint8List> _binaryStream = StreamController<Uint8List>.broadcast();
    final Queue<String> _stringQueue = Queue<String>();
    final Queue<Uint8List> _binaryQueue = Queue<Uint8List>();

    RTCNetworkStream(this._dataChannel)
    {
        _dataChannel.onMessage = _onMessage;
    }

    /// Behandelt eingehende Nachrichten vom RTCDataChannel.
    /// Der Zugriff auf die Queues und Streams wird durch den Mutex geschützt.
    Future<void> _onMessage(RTCDataChannelMessage message) async
    {
        if (message.isBinary)
        {
            await _binaryMutex.acquire(); // Sperren für Binärdaten
            try
            {
                if (_binaryStream.hasListener)
                {
                    print("STREAM");
                    _binaryStream.add(message.binary);
                }
                else
                {
                    print("QUEUE");
                    _binaryQueue.add(message.binary);
                }
            }
            finally
            {
                _binaryMutex.release(); // Unbedingt freigeben
            }
        }
        else
        {
            await _stringMutex.acquire(); // Sperren für Strings
            try
            {
                if (_stringStream.hasListener)
                {
                    print("STREAM");
                    _stringStream.add(message.text);
                }
                else
                {
                    print("QUEUE");
                    _stringQueue.add(message.text);
                }
            }
            finally
            {
                _stringMutex.release(); // Unbedingt freigeben
            }
        }
    }

    /// Liest einen String asynchron vom Stream.
    Future<String> readString() async
    {
        await _stringMutex.acquire(); // Kritischen Bereich sperren

        if (_stringQueue.isNotEmpty)
        {
            // Fall 1: Die Queue hat bereits eine Nachricht.
            final message = _stringQueue.removeFirst();
            _stringMutex.release(); // Sperre sofort freigeben
            return message;
        }
        else
        {
            // Fall 2: Die Queue ist leer, wir müssen auf den Stream warten.
            // WICHTIG: .first erstellt den Listener sofort.
            final future = _stringStream.stream.first;

            // Nachdem der Listener erstellt ist, können wir die Sperre freigeben.
            // Jede neue Nachricht wird nun von _onMessage in den Stream geleitet.
            _stringMutex.release();

            // Jetzt sicher auf die ankommende Nachricht warten.
            return await future;
        }
    }

    /// Liest Binärdaten (Uint8List) asynchron vom Stream.
    Future<Uint8List> readBinary() async
    {
        await _binaryMutex.acquire(); // Kritischen Bereich sperren

        if (_binaryQueue.isNotEmpty)
        {
            final data = _binaryQueue.removeFirst();
            _binaryMutex.release(); // Sperre sofort freigeben
            return data;
        }
        else
        {
            final future = _binaryStream.stream.first;
            _binaryMutex.release(); // Sperre nach Listener-Erstellung freigeben
            return await future;
        }
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

    /// Schließt die Streams und den zugrunde liegenden RTCDataChannel.
    Future<void> close() async
    {
        await _stringStream.close();
        await _binaryStream.close();
        _stringQueue.clear();
        _binaryQueue.clear();
        await _dataChannel.close();
    }
}