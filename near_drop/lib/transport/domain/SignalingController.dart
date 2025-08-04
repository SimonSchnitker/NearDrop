import 'dart:async';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:near_drop/core/domain/entity/Device.dart';
import 'package:near_drop/main.dart';
import 'package:near_drop/nearby/domain/NearbyDevicesContainer.dart';
import 'package:near_drop/transport/data/dto/AnswerDTO.dart';
import 'package:near_drop/transport/data/dto/IceCandidateDTO.dart';
import 'package:near_drop/transport/data/dto/OfferDTO.dart';
import 'package:near_drop/transport/domain/enums/SendResponse.dart';
import 'package:near_drop/transport/domain/event-args/IncomingConnectionEventArgs.dart';
import 'package:near_drop/transport/domain/models/Connection.dart';

import '../data/SignalingGateway.dart';

class SignalingController
{
    final SignalingGateway _signalingGateway;
    final Map<int, Connection> _connections = {};

    StreamController<IncomingConnectionEventArgs> onIncomingConnection = StreamController<IncomingConnectionEventArgs>.broadcast();

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
    Future<void> _onOfferReceived(OfferDTO offer) async
    {
        Device? device = await NearbyDevicesContainer.getByUuid(offer.sender);
        if (device == null)
        {
            dprint("SignalingController: _onOfferReceived: Device not found for UUID ${offer.sender}");
            return;
        }

        final connection = Connection(_signalingGateway, device, offer.connectionId);
        _connections[connection.connectionId] = connection;

        await connection.initializeAsAnswerer(RTCSessionDescription(offer.sdp, offer.sdpType));

        bool established = await connection.isEstablished;
        if (established)
        {
            dprint("SignalingController: _onOfferReceived: Connection established with ${device.name}");
            onIncomingConnection.add(IncomingConnectionEventArgs(device, connection));
        }
        else
        {
            dprint("SignalingController: _onOfferReceived: Failed to establish connection with ${device.name}");
            await connection.close();
            _connections.remove(connection.connectionId);
        }
    }

    /// Wird aufgerufen, wenn eine Antwort empfangen wurde.
    Future<void> _onAnswerReceived(AnswerDTO answer) async
    {
        Connection? connection = _connections[answer.connectionId];
        if (connection == null)
        {
            dprint("SignalingController: _onAnswerReceived: Connection not found for ID ${answer.connectionId}");
            return;
        }

        await connection.setAnswer(RTCSessionDescription(answer.sdp, answer.sdpType));
    }

    /// Wird aufgerufen, wenn ein ICE-Kandidat empfangen wurde.
    Future<void> _onIceCandidateReceived(IceCandidateDTO ice) async
    {
        Connection? connection = _connections[ice.connectionId];
        if (connection == null)
        {
            dprint("SignalingController: _onIceCandidateReceived: Connection not found for ID ${ice.connectionId}");
            return;
        }

        await connection.addIceCandidate(RTCIceCandidate(ice.candidate, ice.sdpMid, ice.sdpMLineIndex));
    }

    /// Versucht, eine Verbindung zu einem Gerät herzustellen.
    Future<Connection?> connect(Device device) async
    {
        int connectionId = DateTime.now().millisecondsSinceEpoch; // Eindeutige ID basierend auf der aktuellen Zeit
        final connection = Connection(_signalingGateway, device, connectionId);
        _connections[connectionId] = connection;

        await connection.initializeAsOfferer();

        bool established = await connection.isEstablished;
        if (established)
        {
            dprint("SignalingController: connect: Connection established with ${device.name}");
            return connection;
        }
        else
        {
            dprint("SignalingController: connect: Failed to establish connection with ${device.name}");
            await connection.close();
            _connections.remove(connection.connectionId);
            return null;
        }
    }

    Future<void> closeConnection(int connectionId) async
    {
        Connection? connection = _connections[connectionId];
        if (connection != null)
        {
            await connection.close();
            _connections.remove(connectionId);
            dprint("SignalingController: closeConnection: Connection $connectionId closed.");
        }
        else
        {
            dprint("SignalingController: closeConnection: Connection $connectionId not found.");
        }
    }
}