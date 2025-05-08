import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'RTCNetworkStream.dart';

/// Speichert die Verbindungsinformationen zu eine Geräts über WebRTC.
class Connection
{
    RTCPeerConnection peerConnection;
    RTCDataChannel? dataChannel;
    RTCNetworkStream? networkStream;

    Connection({required this.peerConnection, this.dataChannel, this.networkStream});

    /// Schließt die Verbindung und gibt alle Ressourcen frei.
    Future<void> close() async
    {
        await networkStream?.close();
        await dataChannel?.close();
        await peerConnection.close();
    }
}