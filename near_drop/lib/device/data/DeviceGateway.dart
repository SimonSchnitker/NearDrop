import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Runtime.dart';
import '../../core/entity/Device.dart';
import '../../core/enums/DeviceType.dart';
import '../../core/enums/OS.dart';

/// Ermöglicht die Kommunikation mit Supabase für Geräte.
class DeviceGateway
{
    /// Legt eine neue UUID für den Benutzer in der Supabase-Datenbank an oder aktualisiert sie und gibt sie zurück.
    Future<String> updateNearbyUuid() async
    {
        return await Supabase.instance.client.rpc<String>("update_nearby_uuid");
    }

    /// Legt ein neues Gerät in der Supabase-Datenbank an.
    Future<(int, Device)> createDevice(String firstname, String deviceName, DeviceType deviceType, OS os, int version, String uuid) async
    {
        final response = await Supabase.instance.client.from("guest_device")
            .insert({"firstname": firstname, "name": deviceName, "type": deviceType.name, "os": os.name, "version": version, "nearby_uuid": uuid, "user_id": Supabase.instance.client.auth.currentUser?.id})
            .select()
            .single();

        int id = response["id"];
        final device = Device(
            response["firstname"],
            response["name"],
            DeviceType.values.byName(response["type"]),
            OS.values.byName(response["os"]),
            response["version"],
            response["nearby_uuid"]);

        return (id, device);
    }

    /// Aktualisiert die übergenenen Werte dieses Geräts, die nicht null sind.
    Future<void> updateDevice({String? firstname, String? deviceName, int? version}) async
    {
        final response = await Supabase.instance.client.from("guest_device")
            .update({
                if (firstname != null) "firstname": firstname,
                if (deviceName != null) "name": deviceName,
                if (version != null) "version": version,
            })
            .eq("id", Runtime.deviceId)
            .select()
            .single();

        if (response.isEmpty)
        {
            throw Exception("Failed to update device");
        }
    }
}