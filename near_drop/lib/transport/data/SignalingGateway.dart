import 'dart:async';
import 'package:near_drop/transport/data/dto/AnswerDTO.dart';
import 'package:near_drop/transport/data/dto/IceCandidateDTO.dart';
import 'package:near_drop/transport/data/dto/OfferDTO.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../Runtime.dart';
import '../../core/domain/entity/Device.dart';

/// Definiert Methoden zum Austauschen von WebRTC-Angeboten, -Antworten und -ICE-Kandidaten.
class SignalingGateway
{
    final onOfferReceived = StreamController<OfferDTO>.broadcast();
    final onAnswerReceived = StreamController<AnswerDTO>.broadcast();
    final onIceCandidateReceived = StreamController<IceCandidateDTO>.broadcast();

    /// Sendet ein WebRTC-Angebot an ein Gerät.
    Future<bool> sendOffer(Device device, RTCSessionDescription offer, String connectionId) async
    {
        final channel = Supabase.instance.client.channel(device.nearbyUuid);
        final result = await channel.sendBroadcastMessage(event: "webrtc-offer", payload: {
            "nearby-uuid": Runtime.nearbyUuid,
            "connectionId": connectionId,
            "sdp": offer.sdp,
            "sdp-type": offer.type,
        });

        return result == ChannelResponse.ok;
    }

    /// Sendet eine WebRTC-Antwort an ein Gerät.
    Future<bool> sendAnswer(Device device, RTCSessionDescription answer, String connectionId) async
    {
        final channel = Supabase.instance.client.channel(device.nearbyUuid);
        final result = await channel.sendBroadcastMessage(event: "webrtc-answer", payload: {
            "nearby-uuid": Runtime.nearbyUuid,
            "connectionId": connectionId,
            "sdp": answer.sdp,
            "sdp-type": answer.type,
        });

        return result == ChannelResponse.ok;
    }

    /// Sendet einen ICE-Kandidaten an ein Gerät.
    Future<bool> sendIceCandidate(Device device, RTCIceCandidate candidate, String connectionId) async
    {
        final channel = Supabase.instance.client.channel(device.nearbyUuid);
        final result = await channel.sendBroadcastMessage(event: "webrtc-ice", payload: {
            "nearby-uuid": Runtime.nearbyUuid,
            "connectionId": connectionId,
            "candidate": candidate.candidate,
            "sdpMid": candidate.sdpMid,
            "sdpMLineIndex": candidate.sdpMLineIndex,
        });

        return result == ChannelResponse.ok;
    }

    /// Sendet eine Batch von ICE-Kandidaten an ein Gerät.
    Future<bool> sendIceCandidateBatch(Device device, List<RTCIceCandidate> candidates, String connectionId) async
    {
        final channel = Supabase.instance.client.channel(device.nearbyUuid);

        final Map<String, dynamic> payload = {
            "nearby-uuid": Runtime.nearbyUuid,
            "connectionId": connectionId,
            "candidates": candidates.map((candidate) => {
                "candidate": candidate.candidate,
                "sdpMid": candidate.sdpMid,
                "sdpMLineIndex": candidate.sdpMLineIndex,
            }).toList(),
        };

        final result = await channel.sendBroadcastMessage(event: "webrtc-ice-batch", payload: payload);
        return result == ChannelResponse.ok;
    }

    /// Wartet auf WebRTC-Events an unserem Channel von anderen Geräten.
    void startListening()
    {
        Runtime.realtimeChannel.onBroadcast(event: "webrtc-offer", callback: (data) async {
            final offer = data["payload"];
            final dto = OfferDTO.fromMap(offer);
            onOfferReceived.add(dto);
        });
        Runtime.realtimeChannel.onBroadcast(event: "webrtc-answer", callback: (data) async {
            final answer = data["payload"];
            final dto = AnswerDTO.fromMap(answer);
            onAnswerReceived.add(dto);
        });
        Runtime.realtimeChannel.onBroadcast(event: "webrtc-ice", callback: (data) async {
            final candidate = data["payload"];
            final dto = IceCandidateDTO.fromMap(candidate);
            onIceCandidateReceived.add(dto);
        });
        Runtime.realtimeChannel.onBroadcast(event: "webrtc-ice-batch", callback: (data) async {
            final payload = data["payload"];
            String sender = payload["nearby-uuid"];
            String connectionId = payload["connectionId"];

            for (final candidate in payload["candidates"])
            {
                final dto = IceCandidateDTO(sender, connectionId, candidate["candidate"], candidate["sdpMid"], candidate["sdpMLineIndex"]);
                onIceCandidateReceived.add(dto);
            }
        });
    }
}