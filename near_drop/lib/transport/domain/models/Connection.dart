import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mutex/mutex.dart';
import 'package:near_drop/core/domain/entity/Device.dart';
import 'package:near_drop/transport/data/Sender.dart';
import 'package:near_drop/transport/data/SignalingGateway.dart';
import '../../../main.dart';
import '../../data/Receiver.dart';

enum Role
{
    notSet, // Rolle ist noch nicht festgelegt
    offerer, // Sender
    answerer, // Empfänger
}

enum ConnectionResult
{
    success,
    timeout,
    canceled,
}

/// Stellt eine WebRTC-Verbindung zu einem anderen Gerät her und verwaltet die DataChannels für den Datenaustausch.
class Connection
{
    static const _waitingForAnswerDuration = Duration(seconds: 3);
    static const _timeout = Duration(seconds: 12);
    static const dataChannelName = "data";
    static const controlChannelName = "control";
    static final configuration = {
        "iceServers":
        [
            {
                'urls': 'stuns:vps.neardrop.app:5349',
            },
            {
                'urls': 'turns:vps.neardrop.app:5349',
                'username': dotenv.env['TURN_USERNAME'],
                'credential': dotenv.env['TURN_CREDENTIAL'],
            }
        ]
    };

    final SignalingGateway _signalingGateway;
    final String connectionId;
    final Device device;
    late RTCPeerConnection peerConnection;
    RTCDataChannel? dataChannel;
    RTCDataChannel? controlChannel;

    final Mutex _puferedIceCandidatesMutex = Mutex(); // Mutex gepufferte für ICE-Kandiden
    Role role = Role.notSet; // Rolle des Verbindungsaufbaus (Offerer oder Answerer)
    Sender? sender;
    Receiver? receiver;

    // Die Completer, der aufgelöst wird, wenn die Verbindung steht (oder fehlschlägt)
    final completer = Completer<ConnectionResult>();
    Future<ConnectionResult> get result => completer.future;

    final List<RTCIceCandidate> _iceCandidateBuffer = [];
    bool _isRemoteDescriptionSet = false;

    Connection(this._signalingGateway, this.device, this.connectionId);

    /// Initialisiert die Verbindung als Offerer (Sender).
    Future<void> initializeAsOfferer() async
    {
        role = Role.offerer;
        peerConnection = await createPeerConnection(configuration);

        // Sender erstellt aktiv die DataChannels
        dataChannel = await peerConnection.createDataChannel(dataChannelName, RTCDataChannelInit());
        controlChannel = await peerConnection.createDataChannel(controlChannelName, RTCDataChannelInit());

        // Listener setzen
        _setPeerConnectionListener();
        _setIceCandidateListener();
        _setOffererDataChannelListeners();

        // Angebot erstellen
        RTCSessionDescription offer = await peerConnection.createOffer();
        await peerConnection.setLocalDescription(offer);

        // Allgemeinen Timeout einrichten
        Future.delayed(_timeout, () {
            if (!completer.isCompleted) completer.complete(ConnectionResult.timeout);
        });

        // Angebot über Supabase senden und ggf. wiederholen
        await _signalingGateway.sendOffer(device, offer, connectionId);
        await Future.delayed(_waitingForAnswerDuration);
        if (!_isRemoteDescriptionSet)
        {
            await _signalingGateway.sendOffer(device, offer, connectionId);

            // Wenn nach doppelter Zeit immernoch keine Antwort kam, ist der Empfänger vermutlich nicht erreichbar
            await Future.delayed(_waitingForAnswerDuration * 2);
            if (!_isRemoteDescriptionSet)
            {
                if (!completer.isCompleted) completer.complete(ConnectionResult.timeout);
            }
        }
    }

    /// Initialisiert die Verbindung als Answerer (Empfänger).
    Future<void> initializeAsAnswerer(RTCSessionDescription offer) async
    {
        role = Role.answerer;
        peerConnection = await createPeerConnection(configuration);
        _setPeerConnectionListener();
        _setIceCandidateListener();
        _setAnswererDataChannelListeners();

        // Remote-Description setzen
        await peerConnection.setRemoteDescription(offer);

        // Antwort erstellen und senden
        RTCSessionDescription answer = await peerConnection.createAnswer();
        await peerConnection.setLocalDescription(answer);
        await _signalingGateway.sendAnswer(device, answer, connectionId);

        // Antwort nochmal senden, falls die Remote-Description nach einer gewissen Zeit noch nicht gesetzt wurde
        await Future.delayed(_waitingForAnswerDuration);
        if (!_isRemoteDescriptionSet)
        {
            await _signalingGateway.sendAnswer(device, answer, connectionId);
            await Future.delayed(_waitingForAnswerDuration * 2);
            if (!_isRemoteDescriptionSet)
            {
                if (!completer.isCompleted) completer.complete(ConnectionResult.timeout);
            }
        }
    }

    /// Setzt die Remote-Description für den Answerer.
    /// Wird aufgerufen, wenn der Offerer eine Antwort erhalten hat.
    Future<void> setAnswer(RTCSessionDescription answer) async
    {
        // Remote-Description setzen
        await peerConnection.setRemoteDescription(answer);
        _isRemoteDescriptionSet = true;

        // Alle gepufferten ICE-Kandidaten senden
        await _sendPufferedIceCandidates();
    }

    void _setPeerConnectionListener()
    {
        peerConnection.onConnectionState = (RTCPeerConnectionState state)
        {
            dprint("PeerConnection state changed: $state");
            if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed || state == RTCPeerConnectionState.RTCPeerConnectionStateFailed)
            {
                close();
                sender?.dispose();
                receiver?.dispose();
            }
        };
    }

    void _setIceCandidateListener()
    {
        peerConnection.onIceCandidate = (RTCIceCandidate candidate)
        {
            dprint("ICE-Kandidat erstellt.");
            if (_isRemoteDescriptionSet)
            {
                _signalingGateway.sendIceCandidate(device, candidate, connectionId);
                iceSendCount++;
                dprint("ICE-Kandidat gesendet: $iceSendCount");
            }
            else
            {
                // Wenn die Remote-Description noch nicht gesetzt ist, speichern wir den Kandidaten im Puffer
                _iceCandidateBuffer.add(candidate);
                dprint("ICE-Kandidat gepuffert, da Remote-Description noch nicht gesetzt ist. Puffergröße: ${_iceCandidateBuffer.length}");
            }
        };
    }

    void _setOffererDataChannelListeners()
    {
        void onStateChanged(RTCDataChannelState state)
        {
            dprint("Channel ${state.name} state changed: $state");

            // Wenn beide Channels offen sind, wurde die Verbindung erfolgreich hergestellt
            if (dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen && controlChannel!.state == RTCDataChannelState.RTCDataChannelOpen)
            {
                sender = Sender(dataChannel!, controlChannel!);
                if (!completer.isCompleted) completer.complete(ConnectionResult.success);
            }
        }

        dataChannel!.onDataChannelState = onStateChanged;
        controlChannel!.onDataChannelState = onStateChanged;
    }

    void _setAnswererDataChannelListeners()
    {
        // Empfänger wartet auf eingehende DataChannels
        peerConnection.onDataChannel = (RTCDataChannel channel)
        {
            dprint("Neuer DataChannel empfangen: ${channel.label}");
            if (channel.label == dataChannelName)
            {
                dataChannel = channel;
                dataChannel!.onDataChannelState = (RTCDataChannelState state) => dprint("DataChannel state changed: $state");
            }
            else if (channel.label == controlChannelName)
            {
                controlChannel = channel;
                controlChannel!.onDataChannelState = (RTCDataChannelState state) => dprint("ControlChannel state changed: $state");
            }

            // Wenn beide Channels offen sind, wurde die Verbindung erfolgreich hergestellt
            if (dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen && controlChannel?.state == RTCDataChannelState.RTCDataChannelOpen)
            {
                receiver = Receiver(dataChannel!, controlChannel!);
                if (!completer.isCompleted) completer.complete(ConnectionResult.success);
            }
        };
    }

    int iceSendCount = 0;
    int iceReceiveCount = 0;

    /// Wird aufgerufen, wenn ein ICE-Kandidat von einem anderen Gerät empfangen wird.
    Future<void> addIceCandidate(RTCIceCandidate candidate) async
    {
        if (role == Role.answerer)
        {
            _isRemoteDescriptionSet = true; // Wenn der Empfänger einen ICE-Kandidaten erhält, ist die Answer beim Offerer angekommen
            if (_iceCandidateBuffer.isNotEmpty) _sendPufferedIceCandidates(); // Alle gepufferten ICE-Kandidaten senden
        }

        try
        {
            await peerConnection.addCandidate(candidate);
            iceReceiveCount++;
            dprint("ICE-Kandidat empfangen: $iceReceiveCount");
        }
        catch (e)
        {
            dprint("Fehler beim Hinzufügen des ICE-Kandidaten: $e");
        }
    }

    /// Sendet die zwischengespeicherten ICE-Kandidaten an den anderen Peer.
    Future<void> _sendPufferedIceCandidates() async
    {
        // Verhindert, dass die gepufferten ICE-Kandidaten mehrmals gesendet werden, wenn mehrere ICE-Kandidaten vom Offerer gleichzeitig empfangen werden.
        await _puferedIceCandidatesMutex.protect(() async {
            if (_iceCandidateBuffer.isNotEmpty)
            {
                await _signalingGateway.sendIceCandidateBatch(device, _iceCandidateBuffer, connectionId);

                iceSendCount += _iceCandidateBuffer.length;
                dprint("Batch von ICE-Kandidaten gesendet: $iceSendCount");

                _iceCandidateBuffer.clear();
            }
        });
    }

    /// Schließt die Verbindung und gibt alle Ressourcen frei.
    Future<void> close() async
    {
        // Hinweis: Oft kommt es beim Schließen zu einer PlatformException. Deshalb abfangen.
        try
        {
            await dataChannel?.close();
        }
        catch (e)
        {
            dprint("Unbekannter Fehler beim Schließen des Data-Kanals: $e");
        }

        try
        {
            await controlChannel?.close();
        }
        catch (e)
        {
            dprint("Unbekannter Fehler beim Schließen des Control-Kanals.: $e");
        }

        try
        {
            await peerConnection.close();
        }
        catch (e)
        {
            dprint("Unbekannter Fehler beim Schließen der PeerConnection: $e");
        }
    }
}