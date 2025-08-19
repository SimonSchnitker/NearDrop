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
import 'package:uuid/uuid.dart';

import '../data/SignalingGateway.dart';

class SignalingController
{
    final SignalingGateway _signalingGateway;
    final Map<Device, Connection> _connections = {};

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

    Connection? getCurrentConnection(Device device)
    {
        return _connections[device];
    }

    /// Wird aufgerufen, wenn ein Angebot empfangen wurde.
    Future<void> _onOfferReceived(OfferDTO offer) async
    {
        Device? device = await NearbyDevicesContainer.getByUuid(offer.nearbyUuid);
        if (device == null)
        {
            dprint("SignalingController: _onOfferReceived: Device not found for UUID ${offer.nearbyUuid}");
            return;
        }

        // Alte Verbindung schließen, falls vorhanden
        Connection? connection = _connections[device];
        if (connection != null)
        {
            await connection.close();
        }

        connection = Connection(_signalingGateway, device, offer.connectionId);
        _connections[device] = connection;

        connection.initializeAsAnswerer(RTCSessionDescription(offer.sdp, offer.sdpType)); // Nicht darauf warten!
        ConnectionResult connectionResult = await connection.result;
        if (connectionResult == ConnectionResult.success)
        {
            dprint("SignalingController: _onOfferReceived: Connection established with ${device.name}");
            onIncomingConnection.add(IncomingConnectionEventArgs(device, connection));
        }
        else
        {
            dprint("SignalingController: _onOfferReceived: Failed to establish connection with ${device.name}");
            await closeConnection(device, connection);
        }
    }

    /// Wird aufgerufen, wenn eine Antwort empfangen wurde.
    Future<void> _onAnswerReceived(AnswerDTO answer) async
    {
        // Wenn das Gerät unbekannt ist, abbrechen
        Device? device = await NearbyDevicesContainer.getByUuid(answer.nearbyUuid);
        if (device == null)
        {
            return;
        }

        Connection? connection = _connections[device];
        if (connection == null || device.nearbyUuid != answer.nearbyUuid)
        {
            dprint("SignalingController: _onAnswerReceived: Connection not found for ID ${answer.connectionId}");
            return;
        }

        await connection.setAnswer(RTCSessionDescription(answer.sdp, answer.sdpType));
    }

    /// Wird aufgerufen, wenn ein ICE-Kandidat empfangen wurde.
    Future<void> _onIceCandidateReceived(IceCandidateDTO ice) async
    {
        // Wenn das Gerät unbekannt ist, abbrechen
        Device? device = await NearbyDevicesContainer.getByUuid(ice.nearbyUuid);
        if (device == null)
        {
            return;
        }

        Connection? connection = _connections[device];
        if (connection == null || connection.device.nearbyUuid != ice.nearbyUuid)
        {
            dprint("SignalingController: _onIceCandidateReceived: Connection not found for ID ${ice.connectionId}");
            return;
        }

        await connection.addIceCandidate(RTCIceCandidate(ice.candidate, ice.sdpMid, ice.sdpMLineIndex));
    }

    /// Versucht, eine Verbindung zu einem Gerät herzustellen.
    Future<(ConnectionResult, Connection?)> connect(Device device) async
    {
        // Alte Verbindung schließen, falls vorhanden
        Connection? connection = _connections[device];
        if (connection != null)
        {
            await connection.close();
        }

        String connectionId = Uuid().v4(); // Zufällige ConnectionId generieren
        connection = Connection(_signalingGateway, device, connectionId);
        _connections[device] = connection;

        connection.initializeAsOfferer(); // Nicht darauf warten!

        ConnectionResult connectionResult = await connection.result;
        if (connectionResult == ConnectionResult.success)
        {
            dprint("SignalingController: connect: Connection established with ${device.name}");
            return (connectionResult, connection);
        }
        else
        {
            dprint("SignalingController: connect: Failed to establish connection with ${device.name}");
            await closeConnection(device, connection);
            return (connectionResult, null);
        }
    }

    /// Schließt eine Verbindung und räumt alle Ressourcen auf.
    Future<void> closeConnection(Device device, Connection connection) async
    {
        await connection.close();

        // Verbindung nur entfernen, wenn sie die aktuelle Verbindung ist
        Connection? currentConnection = _connections[device];
        if (connection == currentConnection)
        {
            _connections.remove(device);
        }

        dprint("SignalingController: closeConnection: Connection ${connection.connectionId} closed.");
    }
}