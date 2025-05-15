import 'package:flutter/widgets.dart';
import 'package:near_drop/core/entity/CommunicationInfo.dart';
import 'package:near_drop/transport/domain/models/Connection.dart';
import '../enums/DeviceType.dart';
import '../enums/OS.dart';

/// Definiert den Aufbau eines Geräts.
class Device extends ChangeNotifier
{
    String firstname;
    String name;
    DeviceType type;
    OS os;
    int version;
    String nearbyUuid;
    final communicationInfo = CommunicationInfo();
    Connection? connection;

    Device(this.firstname, this.name, this.type, this.os, this.version, this.nearbyUuid);

    void updateUsername(String username)
    {
        this.firstname = username;
        notifyListeners();
    }

    Map<String, dynamic> toMap()
    {
        return {
            "firstname": firstname,
            "name": name,
            "type": type.name,
            "os": os.name,
            "version": version,
            "nearby_uuid": nearbyUuid,
        };
    }

    static Device fromMap(Map<String, dynamic> json)
    {
        return Device(
            json["firstname"],
            json["name"],
            DeviceType.values.byName(json["type"]),
            OS.values.byName(json["os"]),
            json["version"],
            json["nearby_uuid"],
        );
    }
}