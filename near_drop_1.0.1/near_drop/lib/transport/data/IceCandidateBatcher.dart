import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mutex/mutex.dart';
import 'package:near_drop/transport/data/SignalingGateway.dart';
import '../../core/domain/entity/Device.dart';

/// Sammelt ICE-Kandidaten und sendet sie in Batches, um die Anzahl der Netzwerk-Nachrichten zu reduzieren.
class IceCandidateBatcher
{
    static const int _maxBatchSize = 6;
    static const Duration _batchTimeout = Duration(milliseconds: 200);

    final SignalingGateway _signalingGateway;
    final Device _device;
    final int _connectionId;

    Timer? _batchTimer;
    final List<RTCIceCandidate> _batch = [];
    final Mutex _mutex = Mutex();
    bool _isDisposed = false;

    IceCandidateBatcher(this._signalingGateway, this._device, this._connectionId);

    /// Fügt einen Kandidaten zum Batch hinzu und plant dessen Versand.
    Future<void> add(RTCIceCandidate candidate) async
    {
        if (_isDisposed)
        {
            return;
        }

        await _mutex.protect(() async {
            _batchTimer?.cancel();
            _batch.add(candidate);
            print("Batcher [${_connectionId}]: Kandidat hinzugefügt. Größe: ${_batch.length}");

            if (_batch.length >= _maxBatchSize)
            {
                await _sendBatchUnprotected();
            }
            else
            {
                _batchTimer = Timer(_batchTimeout, () async {
                    // Timer-Callback muss ebenfalls den Mutex sperren
                    await _mutex.protect(() async {
                        print("Batcher [${_connectionId}]: Batch Timeout erreicht. Sende Batch.");
                        await _sendBatchUnprotected();
                    });
                });
            }
        });
    }

    /// Leert den Batch und sendet die Kandidaten.
    /// /// Diese Methode ist "unprotected" und erwartet, vom Mutex aufgerufen zu werden.
    Future<void> _sendBatchUnprotected() async
    {
        if (_isDisposed || _batch.isEmpty)
        {
            return;
        }

        _batchTimer?.cancel();
        _batchTimer = null;

        print("Batcher [${_connectionId}]: Sende Batch mit ${_batch.length} Kandidaten.");
        await _signalingGateway.sendIceCandidateBatch(_device, _batch, _connectionId);
        _batch.clear();
    }

    void dispose()
    {
        _isDisposed = true;
        _batchTimer?.cancel();
        _batchTimer = null;
        _batch.clear();
    }
}