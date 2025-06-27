import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mutex/mutex.dart';
import 'package:near_drop/nearby/domain/NearbyDevicesContainer.dart';
import 'package:near_drop/transport/data/IceCandidateBatcher.dart';
import 'package:near_drop/transport/data/SignalingGateway.dart';
import 'package:near_drop/transport/domain/event_args/ConnectionCreatedEventArgs.dart';
import 'package:near_drop/transport/domain/models/RTCNetworkStream.dart';
import '../../core/domain/entity/Device.dart';
import '../../core/domain/enums/ErrorState.dart';
import '../../main.dart';
import 'models/Connection.dart';

/// Steuert den Signalisierungsprozess für WebRTC-Verbindungen.
class SignalingController
{
    static const sendRetryCount = 3;
    static const sendRetryDelay = Duration(seconds: 3);
    static const connectTimeoutSeconds = 10;
    static const dataChannelName = "data";
    static const configuration = {
        "iceServers":
        [
            {
                "urls":
                [
                    "stun:stun.l.google.com:19302",
                    "stun:stun.l.google.com:5349",
                    "stun:stun1.l.google.com:3478",
                    "stun:stun1.l.google.com:5349",
                    "stun:stun2.l.google.com:19302",
                    "stun:stun2.l.google.com:5349",
                    "stun:stun3.l.google.com:3478",
                    "stun:stun3.l.google.com:5349",
                    "stun:stun4.l.google.com:19302",
                    "stun:stun4.l.google.com:5349"
                ]
            },
        ]
    };

    // Hier werden ICE-Kandidaten gespeichert, die empfangen wurden, bevor die Verbindung hergestellt wurde. Diese werden später hinzugefügt.
    // Der Key ist die ConnectionId, der Verbindung, die später erzeugt wird.
    // Dies dient dazu, dass später nur die ICE-Kandidaten der Verbindung hinzugefügt werden, die auch tatsächlich zu dieser Verbindung gehören.
    final Map<int, List<RTCIceCandidate>> _earlyIceCandidates = {};
    final Mutex _earlyIceCandidatesMutex = Mutex();

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

    /// Fügt alle zu früh empfangenen ICE-Kandidaten zu einer Verbindung hinzu.
    Future<void> _addEarlyIceCandidatesToConnection(int connectionId, RTCPeerConnection peerConnection) async
    {
        await _earlyIceCandidatesMutex.protect(() async {
            List<RTCIceCandidate> candidates = _earlyIceCandidates[connectionId] ?? [];
            if (candidates.isEmpty)
            {
                dprint("No early ICE candidates to add for connection $connectionId");
                return;
            }

            dprint("Adding ${candidates.length} early ICE candidates to connection $connectionId");
            for (RTCIceCandidate candidate in candidates)
            {
                await peerConnection.addCandidate(candidate);
            }
            _earlyIceCandidates.remove(connectionId); // Entfernen, da sie jetzt hinzugefügt wurden
        });
    }

    /// Wird aufgerufen, wenn ein Angebot empfangen wurde.
    Future<void> _onOfferReceived(Map<String, dynamic> offer) async
    {
        // Überprüfen, ob das Angebot gültig ist
        if (!offer.containsKey("sender") || !offer.containsKey("connectionId") || !offer.containsKey("sdp") || !offer.containsKey("sdp-type"))
        {
            dprint("Ungültiges Angebot empfangen: $offer");
            return;
        }

        // Prüfen, ob das Gerät in unserer Liste vorhanden ist
        Device? device = await NearbyDevicesContainer.getByUuid(offer["sender"]);
        if (device == null)
        {
            dprint("Gerät nicht gefunden: ${offer["sender"]}");
            return;
        }

        // Aktuelle Verbindung zum Gerät schließen, falls vorhanden
        await device.closeCurrentConnection();

        // Angebot auslesen und PeerConnection-Instanz erstellen
        int connectionId = offer["connectionId"];
        RTCSessionDescription sessionDescription = RTCSessionDescription(offer["sdp"], offer["sdp-type"]);
        RTCPeerConnection peerConnection = await createPeerConnection(configuration);

        // Verbindung merken
        Connection connection = Connection(peerConnection: peerConnection, connectionId: connectionId);
        device.communicationInfo.connection = connection;

        // ICE-Kandidaten an Peer senden, wenn sie erstellt wurden
        final IceCandidateBatcher iceCandidateBatcher = IceCandidateBatcher(_signalingGateway, device, connectionId);
        peerConnection.onIceCandidate = (candidate) async {
            await iceCandidateBatcher.add(candidate);
        };

        // Verbindungsstatus zum Peer überwachen
        peerConnection.onConnectionState = (state) async {
            dprint("Verbindungsstatus zu ${device.firstname} (ConnectionId: $connectionId): $state");

            if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed || state == RTCPeerConnectionState.RTCPeerConnectionStateFailed)
            {
                iceCandidateBatcher.dispose();
                await device.closeConnection(connection: connection);
            }
        };

        // Warten, bis der Datenkanal geöffnet ist
        peerConnection.onDataChannel = (RTCDataChannel dataChannel) {
            dprint("Datenkanal empfangen: ${dataChannel.label}");

            // Verbindungsdaten aktualisieren
            connection.dataChannel = dataChannel;
            connection.networkStream = RTCNetworkStream(dataChannel);

            dataChannel.onDataChannelState = (RTCDataChannelState state) async {
                dprint("Datenkanal-Status: $state");

                // Wenn der Datenkanal geöffnet ist, ist die Verbindung hergestellt
                if (state == RTCDataChannelState.RTCDataChannelOpen)
                {
                    dprint("Datenkanal geöffnet: ${dataChannel.label}");
                    onConnectionCreated.add(ConnectionCreatedEventArgs(device, connection, connectionId));
                }
                else if (state == RTCDataChannelState.RTCDataChannelClosed)
                {
                    // Schonmal die UI zurücksetzen und Dialoge schließen, da der Datenkanal meist deutlich eher geschlossen wird als die PeerConnection
                    if (device.communicationInfo.connection?.connectionId == connectionId)
                    {
                        device.communicationInfo.reset();
                        //device.closeOpenDialogs();
                    }
                }
            };
        };

        // Angebot annehmen
        await peerConnection.setRemoteDescription(sessionDescription);

        // ICE-Kandidaten hinzufügen, die vor der Verbindung empfangen wurden
        await _addEarlyIceCandidatesToConnection(connectionId, peerConnection);

        // Antwort erstellen und senden
        RTCSessionDescription answer = await peerConnection.createAnswer();
        await peerConnection.setLocalDescription(answer);

        sendAnswerFunction() async {
            return await _signalingGateway.sendAnswer(device, answer, connectionId);
        }

        bool sent = await _retrySendFunction(sendAnswerFunction, peerConnection);
        if (sent)
        {
            dprint("Antwort gesendet: $connectionId");
        }
        else
        {
            dprint("Antwort konnte nicht gesendet werden.");
            await device.closeConnection(connection: connection, errorState: ErrorState.error);
            return;
        }
    }

    /// Wird aufgerufen, wenn eine Antwort empfangen wurde.
    Future<void> _onAnswerReceived(Map<String, dynamic> answer) async
    {
        // Überprüfen, ob die Antwort gültig ist
        if (!answer.containsKey("sender") || !answer.containsKey("connectionId") || !answer.containsKey("sdp") || !answer.containsKey("sdp-type"))
        {
            dprint("Ungültige Antwort empfangen: $answer");
            return;
        }

        // Prüfen, ob das Gerät in unserer Liste vorhanden ist
        Device? device = await NearbyDevicesContainer.getByUuid(answer["sender"]);
        if (device == null)
        {
            dprint("Gerät nicht gefunden: ${answer["sender"]}");
            return;
        }

        // Prüfen, ob die Verbindung existiert
        Connection? connection = device.communicationInfo.connection;
        if (connection == null)
        {
            dprint("Verbindung nicht gefunden: ${answer["sender"]}");
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
            await device.closeConnection(connection: connection);
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

        int connectionId = candidate["connectionId"];
        RTCIceCandidate iceCandidate = RTCIceCandidate(
            candidate["candidate"],
            candidate["sdpMid"],
            candidate["sdpMLineIndex"],
        );

        Connection? connection = device.communicationInfo.connection;

        // Falls die Verbindung nicht existiert, wird der ICE-Kandidat gespeichert, um später hinzugefügt zu werden
        if (connection == null || connection.peerConnection.getRemoteDescription() == null)
        {
            print("Puffere ICE-Kandidat für zukünftige Connection: $connectionId");
            await _earlyIceCandidatesMutex.protect(() async {
                _earlyIceCandidates.putIfAbsent(connectionId, () => []).add(iceCandidate);
            });
            return;
        }
        else if (connection.connectionId != connectionId)
        {
            print("Alte Verbindung, daher ignorieren: ${candidate["sender"]}");
            return;
        }

        await connection.peerConnection.addCandidate(iceCandidate);
    }

    /// Stellt eine Verbindung zu einem Gerät her.
    Future<Connection?> connect(Device device, int connectionTryCount) async
    {
        Completer<Connection?> completer = Completer<Connection?>();
        device.communicationInfo.connectingCompleter = completer;

        // Verbinden wird abgebrochen, wenn die Verbindung nicht innerhalb des Timeouts hergestellt werden konnte
        Future.delayed(Duration(seconds: connectTimeoutSeconds * connectionTryCount), () {
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
        device.communicationInfo.connection = connection;

        // ICE-Kandidaten an Peer senden, wenn sie erstellt wurden
        final IceCandidateBatcher iceCandidateBatcher = IceCandidateBatcher(_signalingGateway, device, connectionId);
        peerConnection.onIceCandidate = (candidate) async {
            await iceCandidateBatcher.add(candidate);
        };

        // Verbindungsstatus zum Peer überwachen
        peerConnection.onConnectionState = (state) async {
            print("Verbindungsstatus zu ${device.firstname} (ConnectionId: $connectionId): $state");

            if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed || state == RTCPeerConnectionState.RTCPeerConnectionStateFailed)
            {
                iceCandidateBatcher.dispose();
                await device.closeConnection(connection: connection);
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
                if (device.communicationInfo.connection?.connectionId == connectionId)
                {
                    device.communicationInfo.reset();
                    //device.closeOpenDialogs();
                }
            }
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
            // Wenn die PeerConnection mittlerweile geschlossen wurde, dann abbrechen.
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