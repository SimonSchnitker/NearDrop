import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:near_drop/core/entity/Device.dart';
import 'package:near_drop/nearby/domain/NearbyDevicesContainer.dart';
import 'package:near_drop/transport/data/SignalingGateway.dart';
import 'package:near_drop/transport/domain/event_args/ConnectionCreatedEventArgs.dart';
import 'package:near_drop/transport/domain/models/RTCNetworkStream.dart';
import 'models/Connection.dart';

class SignalingController
{
    static const dataChannelName = "data";
    static const configuration = {
        "iceServers": [
            {
                "urls": "stun:stun.l.google.com:19302"
            },
        ]
    };

    final SignalingGateway _signalingGateway;
    StreamController<ConnectionCreatedEventArgs> onConnectionCreated = StreamController<ConnectionCreatedEventArgs>.broadcast();

    SignalingController(this._signalingGateway)
    {
        _signalingGateway.onOfferReceived.stream.listen(_onOfferReceived);
        _signalingGateway.onAnswerReceived.stream.listen(_onAnswerReceived);
        _signalingGateway.onIceCandidateReceived.stream.listen(_onIceCandidateReceived);
    }

    /// Startet den Signalisierungsprozess und wartet auf eingehende Angebote.
    void startListening()
    {
        _signalingGateway.startListening();
    }

    /// Wird aufgerufen, wenn ein Angebot empfangen wurde.
    Future<void> _onOfferReceived(Map<String, dynamic> offer) async
    {

        // Überprüfen, ob das Angebot gültig ist
        if (!offer.containsKey("sender") || !offer.containsKey("connectionId") || !offer.containsKey("sdp") || !offer.containsKey("sdp-type"))
        {
            print("Ungültiges Angebot empfangen: $offer");
            return;
        }

        // Prüfen, ob das Gerät in unserer Liste vorhanden ist
        Device? device = await NearbyDevicesContainer.getByUuid(offer["sender"]);
        if (device == null)
        {
            print("Gerät nicht gefunden: ${offer["sender"]}");
            return;
        }

        // Verbindungen zum Gerät schließen, sollten versehentlich noch welche offen sein
        if (device.connections.isNotEmpty)
        {
            //await clearAllConnections(device);
        }

        // Angebot auslesen und PeerConnection-Instanz erstellen
        int connectionId = offer["connectionId"];
        RTCSessionDescription sessionDescription = RTCSessionDescription(offer["sdp"], offer["sdp-type"]);
        RTCPeerConnection peerConnection = await createPeerConnection(configuration);

        // Verbindung merken
        Connection connection = Connection(peerConnection: peerConnection);
        device.connections[connectionId] = connection;

        // Verbindungsstatus zum Peer überwachen
        peerConnection.onConnectionState = (state) async {
            print("Verbindungsstatus zu ${device.firstname} (ConnectionId: $connectionId): $state");

            if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected || state == RTCPeerConnectionState.RTCPeerConnectionStateClosed || state == RTCPeerConnectionState.RTCPeerConnectionStateFailed)
            {
                await clearConnection(device, connectionId);
            }
        };

        // ICE-Kandidaten an Peer senden, wenn sie erstellt wurden
        peerConnection.onIceCandidate = (candidate) async {
            await _signalingGateway.sendIceCandidate(device, candidate, connectionId);
        };

        // Warten, bis der Datenkanal geöffnet ist
        peerConnection.onDataChannel = (RTCDataChannel dataChannel) {
            print("Datenkanal empfangen: ${dataChannel.label}");

            // Verbindungsdaten aktualisieren
            connection.dataChannel = dataChannel;
            connection.networkStream = RTCNetworkStream(dataChannel);

            dataChannel.onDataChannelState = (RTCDataChannelState state) async {
                print("Datenkanal-Status: $state");

                // Wenn der Datenkanal geöffnet ist, ist die Verbindung hergestellt
                if (state == RTCDataChannelState.RTCDataChannelOpen)
                {
                    print("Datenkanal geöffnet: ${dataChannel.label}");
                    onConnectionCreated.add(ConnectionCreatedEventArgs(device, connection, connectionId));
                }
            };
        };

        // Angebot annehmen
        await peerConnection.setRemoteDescription(sessionDescription);
        RTCSessionDescription answer = await peerConnection.createAnswer();
        await peerConnection.setLocalDescription(answer);

        // Antwort an das Gerät senden
        bool sent = await _signalingGateway.sendAnswer(device, answer, connectionId);
        if (!sent)
        {
            print("Antwort konnte nicht gesendet werden.");
            //await clearConnection(device);
        }
    }

    /// Wird aufgerufen, wenn eine Antwort empfangen wurde.
    Future<void> _onAnswerReceived(Map<String, dynamic> answer) async
    {
        // Überprüfen, ob die Antwort gültig ist
        if (!answer.containsKey("sender") || !answer.containsKey("connectionId") || !answer.containsKey("sdp") || !answer.containsKey("sdp-type"))
        {
            print("Ungültige Antwort empfangen: $answer");
            return;
        }

        // Prüfen, ob das Gerät in unserer Liste vorhanden ist
        Device? device = await NearbyDevicesContainer.getByUuid(answer["sender"]);
        if (device == null)
        {
            print("Gerät nicht gefunden: ${answer["sender"]}");
            return;
        }

        // Prüfen, ob die Verbindung existiert
        Connection? connection = device.connections[answer["connectionId"]];
        if (connection == null)
        {
            print("Verbindung nicht gefunden: ${answer["sender"]}");
            return;
        }

        RTCSessionDescription sessionDescription = RTCSessionDescription(answer["sdp"], answer["sdp-type"]);
        await connection.peerConnection.setRemoteDescription(sessionDescription);
    }

    /// Wird aufgerufen, wenn ein ICE-Kandidat empfangen wurde.
    Future<void> _onIceCandidateReceived(Map<String, dynamic> candidate) async
    {
        // Überprüfen, ob der ICE-Kandidat gültig ist
        if (!candidate.containsKey("sender") || !candidate.containsKey("connectionId") || !candidate.containsKey("sdpMid") || !candidate.containsKey("sdpMLineIndex") || !candidate.containsKey("candidate"))
        {
            print("Ungültiger ICE-Kandidat empfangen: $candidate");
            return;
        }

        // Prüfen, ob das Gerät in unserer Liste vorhanden ist
        Device? device = await NearbyDevicesContainer.getByUuid(candidate["sender"]);
        if (device == null)
        {
            print("Gerät nicht gefunden: ${candidate["sender"]}");
            return;
        }

        // Prüfen, ob die Verbindung existiert
        Connection? connection = device.connections[candidate["connectionId"]];
        if (connection == null)
        {
            print("Verbindung nicht gefunden: ${candidate["sender"]}");
            return;
        }

        RTCIceCandidate iceCandidate = RTCIceCandidate(
            candidate["candidate"],
            candidate["sdpMid"],
            candidate["sdpMLineIndex"],
        );

        await connection.peerConnection.addCandidate(iceCandidate);
    }

    /// Stellt eine Verbindung zu einem Gerät her.
    Future<Connection?> connect(Device device) async
    {
        if (device.connections.isNotEmpty)
        {
            //await clearAllConnections(device);
        }

        Completer<Connection?> completer = Completer<Connection?>();

        // Als ConnectionId wird die aktuelle Zeit verwendet
        int connectionId = DateTime.now().millisecondsSinceEpoch;

        // PeerConnection-Instanz erstellen
        RTCPeerConnection peerConnection = await createPeerConnection(configuration);

        // Verbindungsstatus zum Peer überwachen
        peerConnection.onConnectionState = (state) async {
            print("Verbindungsstatus zu ${device.firstname} (ConnectionId: $connectionId): $state");

            if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected || state == RTCPeerConnectionState.RTCPeerConnectionStateClosed || state == RTCPeerConnectionState.RTCPeerConnectionStateFailed)
            {
                await clearConnection(device, connectionId);
            }
        };

        // ICE-Kandidaten an Peer senden, wenn sie erstellt wurden
        peerConnection.onIceCandidate = (candidate) async {
            await _signalingGateway.sendIceCandidate(device, candidate, connectionId);
        };

        // DataChannel erstellen
        RTCDataChannel dataChannel = await peerConnection.createDataChannel(dataChannelName, RTCDataChannelInit());

        // Verbindung merken
        Connection connection = Connection(peerConnection: peerConnection, dataChannel: dataChannel, networkStream: RTCNetworkStream(dataChannel));
        device.connections[connectionId] = connection;

        // DataChannel-Status überwachen
        dataChannel.onDataChannelState = (RTCDataChannelState state) async {
            print("DataChannel-Status: $state");

            // Wenn der Datenkanal geöffnet ist, ist die Verbindung hergestellt
            if (state == RTCDataChannelState.RTCDataChannelOpen)
            {
                if (!completer.isCompleted)
                {
                    completer.complete(connection);
                }
            }
        };

        // Angebot erstellen
        RTCSessionDescription offer = await peerConnection.createOffer();
        await peerConnection.setLocalDescription(offer);

        // Angebot über Supabase an Gerät senden
        bool sent = await _signalingGateway.sendOffer(device, offer, connectionId);
        if (!sent)
        {
            print("Angebot konnte nicht gesendet werden.");
            await clearConnection(device, connectionId);
            completer.complete(null);
        }

        return await completer.future;
    }

    /// Schließt eine Verbindung zu einem Gerät.
    Future<void> clearConnection(Device device, int connectionId) async
    {
        Connection? connection = device.connections[connectionId];
        if (connection == null)
        {
            return;
        }

        await connection.close();
        device.connections.remove(connectionId);
    }
}