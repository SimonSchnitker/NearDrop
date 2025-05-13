import 'package:flutter/services.dart';
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
        // Hinweis: Oft kommt es hier zu einer PlatformException. Deshalb abfangen.
        try
        {
            await networkStream?.close(); // Schließt ebenfalls den DataChannel
        }
        catch (e)
        {
            print("Unbekannter Fehler beim Schließen der Verbindung: $e");
        }

        try
        {
            await peerConnection.close();
        }
        catch (e)
        {
            print("Unbekannter Fehler beim Schließen der Verbindung: $e");
        }
    }
}