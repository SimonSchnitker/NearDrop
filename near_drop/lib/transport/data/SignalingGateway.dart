import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:near_drop/Runtime.dart';
import 'package:near_drop/core/entity/Device.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Definiert Methoden zum Austauschen von WebRTC-Angeboten, -Antworten und -ICE-Kandidaten.
class SignalingGateway
{
    final onOfferReceived = StreamController<Map<String, dynamic>>.broadcast();
    final onAnswerReceived = StreamController<Map<String, dynamic>>.broadcast();
    final onIceCandidateReceived = StreamController<Map<String, dynamic>>.broadcast();

    /// Sendet ein WebRTC-Angebot an ein Gerät.
    Future<bool> sendOffer(Device device, RTCSessionDescription offer, int connectionId) async
    {
        final channel = Supabase.instance.client.channel(device.nearbyUuid);
        final result = await channel.sendBroadcastMessage(event: "webrtc-offer", payload: {
            "sender": Runtime.nearbyUuid,
            "connectionId": connectionId,
            "sdp": offer.sdp,
            "sdp-type": offer.type,
        });

        return result == ChannelResponse.ok;
    }

    /// Sendet eine WebRTC-Antwort an ein Gerät.
    Future<bool> sendAnswer(Device device, RTCSessionDescription answer, int connectionId) async
    {
        final channel = Supabase.instance.client.channel(device.nearbyUuid);
        final result = await channel.sendBroadcastMessage(event: "webrtc-answer", payload: {
            "sender": Runtime.nearbyUuid,
            "connectionId": connectionId,
            "sdp": answer.sdp,
            "sdp-type": answer.type,
        });

        return result == ChannelResponse.ok;
    }

    /// Sendet einen ICE-Kandidaten an ein Gerät.
    Future<bool> sendIceCandidate(Device device, RTCIceCandidate candidate, int connectionId) async
    {
        final channel = Supabase.instance.client.channel(device.nearbyUuid);
        final result = await channel.sendBroadcastMessage(event: "webrtc-ice", payload: {
            "sender": Runtime.nearbyUuid,
            "connectionId": connectionId,
            "candidate": candidate.candidate,
            "sdpMid": candidate.sdpMid,
            "sdpMLineIndex": candidate.sdpMLineIndex,
        });

        return result == ChannelResponse.ok;
    }

    /// Wartet auf WebRTC-Events an unserem Channel von anderen Geräten.
    void startListening()
    {
        print("Listening for WebRTC evefgnts...");

        Runtime.realtimeChannel.onBroadcast(event: "webrtc-offer", callback: (data) async {
            final offer = data["payload"];
            onOfferReceived.add(offer);
        });
        Runtime.realtimeChannel.onBroadcast(event: "webrtc-answer", callback: (data) async {
            final answer = data["payload"];
            onAnswerReceived.add(answer);
        });
        Runtime.realtimeChannel.onBroadcast(event: "webrtc-ice", callback: (data) async {
            final candidate = data["payload"];
            onIceCandidateReceived.add(candidate);
        });
    }
}