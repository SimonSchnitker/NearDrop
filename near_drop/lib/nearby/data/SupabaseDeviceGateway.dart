import 'dart:async';
import 'package:near_drop/Runtime.dart';
import 'package:near_drop/core/Version.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/domain/entity/Device.dart';
import '../../core/domain/enums/DeviceType.dart';
import '../../core/domain/enums/OS.dart';

/// Gateway für die Kommunikation mit anderen Geräten in der Nähe.
class SupabaseDeviceGateway
{
    final StreamController<Device> onDeviceDataReceived = StreamController<Device>.broadcast();
    final StreamController<String> onAcknowledgementReceived = StreamController<String>.broadcast();

    /// Sendet unsere Gerätedaten an ein anderes Gerät über Supabase.
    Future<bool> sendDeviceData(String destinationUuid, bool attachAck) async
    {
        RealtimeChannel channel = Supabase.instance.client.channel(destinationUuid);

        final payload = {
            "uuid": Runtime.nearbyUuid,
            "firstname": Runtime.firstname,
            "name": Runtime.deviceName,
            "dtype": Runtime.deviceType.index, // Der Name "type" ist von Supabase reserviert, daher "dtype" verwenden
            "os": Runtime.os.index,
            "version": Runtime.appVersion.toString(),
        };

        if (attachAck)
        {
            payload["isAck"] = true; // Acknowledgement anhängen
        }

        ChannelResponse response = await channel.sendBroadcastMessage(event: "device", payload: payload);
        return response == ChannelResponse.ok;
    }

    Future<bool> sendAcknowledgement(String destinationUuid) async
    {
        RealtimeChannel channel = Supabase.instance.client.channel(destinationUuid);
        ChannelResponse response = await channel.sendBroadcastMessage(event: "device_ack", payload: {
            "uuid": Runtime.nearbyUuid,
        });

        return response == ChannelResponse.ok;
    }

    /// Startet das Lauschen auf Gerätedaten.
    void startListeningForDeviceData()
    {
        Runtime.realtimeChannel.onBroadcast(event: "device_ack", callback: (data) async
        {
            data = data["payload"];
            String nearbyUuid = data["uuid"];
            onAcknowledgementReceived.add(nearbyUuid);
        });
        Runtime.realtimeChannel.onBroadcast(event: "device", callback: (data) async
        {
            data = data["payload"];
            String nearbyUuid = data["uuid"];
            String firstname = data["firstname"];
            String name = data["name"];
            int type = data["dtype"]; // Der Name "type" ist von Supabase reserviert, daher "device_type" verwenden
            int os = data["os"];
            String version = data["version"];

            Device device = Device(
                firstname,
                name,
                DeviceType.values[type],
                OS.values[os],
                Version.fromString(version),
                nearbyUuid
            );

            onDeviceDataReceived.add(device);

            // Prüfen, ob das Acknowledgement mitgesendet wurde
            bool? isAcknowledge = data["isAck"];
            if (isAcknowledge == true)
            {
                onAcknowledgementReceived.add(nearbyUuid);
            }
        });
    }
}