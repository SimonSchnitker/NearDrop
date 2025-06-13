import 'dart:async';
import 'package:near_drop/Runtime.dart';
import 'package:near_drop/core/AppVersion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/domain/entity/Device.dart';
import '../../core/domain/enums/DeviceType.dart';
import '../../core/domain/enums/OS.dart';

/// Gateway für die Kommunikation mit anderen Geräten in der Nähe.
class SupabaseDeviceGateway
{
    final StreamController<Device> onDeviceDataReceived = StreamController<Device>.broadcast();
    final StreamController<String> onDeviceRequestReceived = StreamController<String>.broadcast();

    /// Fordert die Gerätedaten eines anderen Geräts an.
    Future<bool> sendDeviceDataRequest(String destinationUuid) async
    {
        RealtimeChannel channel = Supabase.instance.client.channel(destinationUuid);
        ChannelResponse response = await channel.sendBroadcastMessage(event: "device_request", payload: {
            "sender": Runtime.nearbyUuid,
        });

        return response == ChannelResponse.ok;
    }

    /// Sendet unsere Gerätedaten an ein anderes Gerät über Supabase.
    Future<bool> sendDeviceData(String destinationUuid) async
    {
        RealtimeChannel channel = Supabase.instance.client.channel(destinationUuid);
        ChannelResponse response = await channel.sendBroadcastMessage(event: "device", payload: {
            "sender": Runtime.nearbyUuid,
            "firstname": Runtime.firstname,
            "deviceName": Runtime.deviceName,
            "deviceType": Runtime.deviceType.name,
            "os": Runtime.os.name,
            "version": Runtime.appVersion.toString(),
        });

        return response == ChannelResponse.ok;
    }

    /// Startet das Lauschen auf Gerätedaten.
    void startListeningForDeviceData()
    {
        Runtime.realtimeChannel.onBroadcast(event: "device_request", callback: (data) async
        {
            data = data["payload"];
            String nearbyUuid = data["sender"];
            onDeviceRequestReceived.add(nearbyUuid);
        });

        Runtime.realtimeChannel.onBroadcast(event: "device", callback: (data) async
        {
            data = data["payload"];
            String nearbyUuid = data["sender"];
            String firstname = data["firstname"];
            String name = data["deviceName"];
            String type = data["deviceType"];
            String os = data["os"];
            String version = data["version"];

            Device device = Device(
                firstname,
                name,
                DeviceType.values.byName(type),
                OS.values.byName(os),
                AppVersion.fromString(version),
                nearbyUuid
            );

            onDeviceDataReceived.add(device);
        });
    }
}