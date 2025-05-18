import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:near_drop/core/entity/Device.dart';
import 'package:near_drop/nearby/domain/NearbyDevicesContainer.dart';
import 'package:near_drop/transport/data/SignalingGateway.dart';
import 'package:near_drop/transport/domain/event_args/ConnectionCreatedEventArgs.dart';
import 'package:near_drop/transport/domain/models/RTCNetworkStream.dart';
import 'models/Connection.dart';

class SignalingController
{
    static const sendRetryCount = 3;
    static const sendRetryDelay = Duration(seconds: 3);
    static const connectTimeout = Duration(seconds: 15);
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

        // Aktuelle Verbindung zum Gerät schließen, falls vorhanden
        await device.connection?.close();

        // Angebot auslesen und PeerConnection-Instanz erstellen
        int connectionId = offer["connectionId"];
        RTCSessionDescription sessionDescription = RTCSessionDescription(offer["sdp"], offer["sdp-type"]);
        RTCPeerConnection peerConnection = await createPeerConnection(configuration);

        // Verbindung merken
        Connection connection = Connection(peerConnection: peerConnection, connectionId: connectionId);
        device.connection = connection;

        // Verbindungsstatus zum Peer überwachen
        peerConnection.onConnectionState = (state) async {
            print("Verbindungsstatus zu ${device.firstname} (ConnectionId: $connectionId): $state");

            if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed || state == RTCPeerConnectionState.RTCPeerConnectionStateFailed)
            {
                // Wenn die aktuelle Verbindung geschlossen wurde, die Kommunikationsdaten zurücksetzen
                if (device.connection?.connectionId == connectionId)
                {
                    await device.clearConnection();
                }
            }
        };

        // ICE-Kandidaten an Peer senden, wenn sie erstellt wurden
        peerConnection.onIceCandidate = (candidate) async {
            sendIceCandidateFunction() async {
                return await _signalingGateway.sendIceCandidate(device, candidate, connectionId);
            }

            bool sent = await _retrySendFunction(sendIceCandidateFunction, peerConnection);
            if (sent)
            {
                print("ICE-Kandidat gesendet: $connectionId");
            }
            else
            {
                print("ICE-Kandidat konnte nicht gesendet werden.");
            }
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
                else if (state == RTCDataChannelState.RTCDataChannelClosed)
                {
                    // Schonmal die UI zurücksetzen und Dialoge schließen, da der Datenkanal meist deutlich eher geschlossen wird als die PeerConnection
                    if (device.connection?.connectionId == connectionId)
                    {
                        device.communicationInfo.reset();
                        device.closeOpenDialogs();
                    }
                }
            };
        };

        // Angebot annehmen
        await peerConnection.setRemoteDescription(sessionDescription);
        RTCSessionDescription answer = await peerConnection.createAnswer();
        await peerConnection.setLocalDescription(answer);

        // Antwort an das Gerät senden
        sendAnswerFunction() async {
            return await _signalingGateway.sendAnswer(device, answer, connectionId);
        }

        bool sent = await _retrySendFunction(sendAnswerFunction, peerConnection);
        if (sent)
        {
            print("Antwort gesendet: $connectionId");
        }
        else
        {
            print("Antwort konnte nicht gesendet werden.");
            await connection.close();
            device.connection = null;
            return;
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
        Connection? connection = device.connection;
        if (connection == null)
        {
            print("Verbindung nicht gefunden: ${answer["sender"]}");
            return;
        }
        else if (connection.connectionId != answer["connectionId"])
        {
            print("Alte Verbindung, daher ignorieren: ${answer["sender"]}");
            return;
        }

        // Prüfen, ob Verbindung im gültigen Signalisierungs-Zustand ist
        if (connection.peerConnection.signalingState != RTCSignalingState.RTCSignalingStateHaveLocalOffer)
        {
            print("Verbindung nicht im gültigen Zustand: ${connection.peerConnection.signalingState}");
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
        Connection? connection = device.connection;
        if (connection == null)
        {
            print("Verbindung nicht gefunden: ${candidate["sender"]}");
            return;
        }
        else if (connection.connectionId != candidate["connectionId"])
        {
            print("Alte Verbindung, daher ignorieren: ${candidate["sender"]}");
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
        // Aktuelle Verbindung zum Gerät schließen, falls vorhanden
        await device.connection?.close();

        Completer<Connection?> completer = Completer<Connection?>();

        // Verbinden wird abgebrochen, wenn die Verbindung nicht innerhalb des Timeouts hergestellt werden konnte
        Future.delayed(connectTimeout, () {
            if (!completer.isCompleted)
            {
                completer.complete(null);
            }
        });

        // Als ConnectionId wird die aktuelle Zeit verwendet
        int connectionId = DateTime.now().millisecondsSinceEpoch;

        // PeerConnection-Instanz erstellen
        RTCPeerConnection peerConnection = await createPeerConnection(configuration);

        // DataChannel erstellen
        RTCDataChannel dataChannel = await peerConnection.createDataChannel(dataChannelName, RTCDataChannelInit());

        // Verbindung merken
        Connection connection = Connection(peerConnection: peerConnection, connectionId: connectionId, dataChannel: dataChannel, networkStream: RTCNetworkStream(dataChannel));
        device.connection = connection;

        // Verbindungsstatus zum Peer überwachen
        peerConnection.onConnectionState = (state) async {
            print("Verbindungsstatus zu ${device.firstname} (ConnectionId: $connectionId): $state");

            if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed || state == RTCPeerConnectionState.RTCPeerConnectionStateFailed)
            {
                // Wenn die aktuelle Verbindung geschlossen wurde, die Kommunikationsdaten zurücksetzen
                if (device.connection?.connectionId == connectionId)
                {
                    await device.clearConnection();
                }
            }
        };

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
            else if (state == RTCDataChannelState.RTCDataChannelClosed)
            {
                // Schonmal die UI zurücksetzen und Dialoge schließen, da der Datenkanal meist deutlich eher geschlossen wird als die PeerConnection
                if (device.connection?.connectionId == connectionId)
                {
                    device.communicationInfo.reset();
                    device.closeOpenDialogs();
                }
            }
        };

        // ICE-Kandidaten an Peer senden, wenn sie erstellt wurden
        peerConnection.onIceCandidate = (candidate) async {
            sendIceCandidateFunction() async {
                return await _signalingGateway.sendIceCandidate(device, candidate, connectionId);
            }

            bool sent = await _retrySendFunction(sendIceCandidateFunction, peerConnection);
            if (sent)
            {
                print("ICE-Kandidat gesendet: $connectionId");
            }
            else
            {
                print("ICE-Kandidat konnte nicht gesendet werden.");
            }
        };

        peerConnection.onSignalingState = (state) {
            print("Signalisierungsstatus ($connectionId): $state");
        };

        // Angebot erstellen
        RTCSessionDescription offer = await peerConnection.createOffer();
        await peerConnection.setLocalDescription(offer);

        sendOfferFunction() async {
            return await _signalingGateway.sendOffer(device, offer, connectionId);
        }

        bool sent = await _retrySendFunction(sendOfferFunction, peerConnection);
        if (sent)
        {
            print("Angebot gesendet: $connectionId");
        }
        else
        {
            print("Angebot konnte nicht gesendet werden.");
            completer.complete(null);
            return null;
        }

        return await completer.future;
    }

    /// Führt eine Funktion mit mehreren Wiederholungen aus, wenn sie fehlschlägt.
    Future<bool> _retrySendFunction(Future<bool> Function() function, RTCPeerConnection peerConnection) async
    {
        for (int i = 0; i < sendRetryCount; i++)
        {
            if (peerConnection.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateClosed || peerConnection.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected || peerConnection.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateFailed)
            {
                return false;
            }

            if (await function())
            {
                return true;
            }
            await Future.delayed(sendRetryDelay);
        }
        return false;
    }
}