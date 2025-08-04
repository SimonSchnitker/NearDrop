import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:near_drop/core/domain/entity/Device.dart';
import 'package:near_drop/transport/data/SignalingGateway.dart';
import '../../../main.dart';

/// Stellt eine WebRTC-Verbindung zu einem anderen Gerät her und verwaltet die DataChannels für den Datenaustausch.
class Connection
{
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
    final int connectionId;
    final Device device;
    late RTCPeerConnection peerConnection;
    RTCDataChannel? dataChannel;
    RTCDataChannel? controlChannel;

    // Die Completer, der aufgelöst wird, wenn die Verbindung steht (oder fehlschlägt)
    final _completer = Completer<bool>();
    Future<bool> get isEstablished => _completer.future;

    final List<RTCIceCandidate> _iceCandidateBuffer = [];
    bool _isRemoteDescriptionSet = false;

    Connection(this._signalingGateway, this.device, this.connectionId);

    /// Initialisiert die Verbindung als Offerer (Sender).
    Future<void> initializeAsOfferer() async
    {
        peerConnection = await createPeerConnection(configuration);

        // Sender erstellt aktiv die DataChannels
        dataChannel = await peerConnection.createDataChannel(dataChannelName, RTCDataChannelInit());
        controlChannel = await peerConnection.createDataChannel(controlChannelName, RTCDataChannelInit());

        // Listener setzen
        _setPeerConnectionListener();
        _setIceCandidateListener();
        _setOffererDataChannelListeners();

        // Angebot erstellen und über Supabase senden
        RTCSessionDescription offer = await peerConnection.createOffer();
        await peerConnection.setLocalDescription(offer);
        await _signalingGateway.sendOffer(device, offer, connectionId);
    }

    /// Initialisiert die Verbindung als Answerer (Empfänger).
    Future<void> initializeAsAnswerer(RTCSessionDescription offer) async
    {
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
        _isRemoteDescriptionSet = true; // Erst jetzt setzen, damit erst jetzt neu erstellte ICE-Kandidaten gesendet werden

        // Alle gepufferten ICE-Kandidaten senden
        await _sendPufferedIceCandidates();
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
            }
        };
    }

    void _setIceCandidateListener()
    {
        peerConnection.onIceCandidate = (RTCIceCandidate candidate)
        {
            dprint("ICE-Kandidat empfangen: $candidate");
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
                _completer.complete(true);
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
                _completer.complete(true);
            }
        };
    }

    int iceSendCount = 0;
    int iceReceiveCount = 0;

    /// Wird aufgerufen, wenn ein ICE-Kandidat von einem anderen Gerät empfangen wird.
    Future<void> addIceCandidate(RTCIceCandidate candidate) async
    {
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

    Future<void> _sendPufferedIceCandidates() async
    {
        if (_iceCandidateBuffer.isNotEmpty)
        {
            await _signalingGateway.sendIceCandidateBatch(device, _iceCandidateBuffer, connectionId);

            iceSendCount += _iceCandidateBuffer.length;
            dprint("Batch von ICE-Kandidaten gesendet: $iceSendCount");

            _iceCandidateBuffer.clear();
        }
    }

    /// Schließt die Verbindung und gibt alle Ressourcen frei.
    Future<void> close() async
    {
        // Hinweis: Oft kommt es beim Schließen zu einer PlatformException. Deshalb abfangen.
        try
        {
            await dataChannel?.close();
            await controlChannel?.close();
            await peerConnection.close();
        }
        catch (e)
        {
            dprint("Unbekannter Fehler beim Schließen der Verbindung: $e");
        }
    }
}