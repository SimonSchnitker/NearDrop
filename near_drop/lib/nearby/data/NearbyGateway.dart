import 'dart:async';
import 'package:near_drop/Runtime.dart';
import 'package:near_drop/core/entity/Device.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/enums/DeviceType.dart';
import '../../core/enums/OS.dart';

class NearbyGateway
{
    final StreamController<Device> onDeviceDataReceived = StreamController<Device>.broadcast();

    /// Sendet unsere Gerätedaten an ein anderes Gerät über Supabase.
    Future<bool> sendDeviceData(String destinationUuid) async
    {
        RealtimeChannel channel = Supabase.instance.client.channel(destinationUuid);
        ChannelResponse response = await channel.sendBroadcastMessage(event: "device", payload: {
            "sender": Runtime.nearbyUuid,
            "firstname": Runtime.firstname,
            "name": Runtime.deviceName,
            "device_type": Runtime.deviceType.index,
            "os": Runtime.os.index,
            "version": Runtime.version,
        });

        return response == ChannelResponse.ok;
    }

    /// Startet das Lauschen auf Gerätedaten.
    void startListeningForDeviceData()
    {
        Runtime.realtimeChannel.onBroadcast(event: "device", callback: (data) async
        {
            data = data["payload"];
            String nearbyUuid = data["sender"];
            String firstname = data["firstname"];
            String name = data["name"];
            int type = data["device_type"];
            int os = data["os"];
            int version = data["version"];

            Device device = Device(
                firstname,
                name,
                DeviceType.values[type],
                OS.values[os],
                version,
                nearbyUuid
            );

            onDeviceDataReceived.add(device);
        });
    }
}