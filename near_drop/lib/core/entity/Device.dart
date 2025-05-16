import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:near_drop/core/entity/CommunicationInfo.dart';
import 'package:near_drop/transport/domain/models/Connection.dart';
import '../enums/DeviceType.dart';
import '../enums/OS.dart';

/// Definiert den Aufbau eines Geräts.
class Device extends ChangeNotifier
{
    // Keys und Boolean-Werte für Dialoge, die zum Gerät gehören, um sie von überall aus schließen zu können.
    final GlobalKey<NavigatorState> sendRequestDialogKey = GlobalKey<NavigatorState>();
    final GlobalKey<NavigatorState> cancelTransportDialogKey = GlobalKey<NavigatorState>();
    bool isSendRequestDialogOpen = false;
    bool isCancelTransportDialogOpen = false;

    StreamController onCanceledCompleted = StreamController.broadcast();

    String firstname;
    String name;
    DeviceType type;
    OS os;
    int version;
    String nearbyUuid;
    final communicationInfo = CommunicationInfo();
    Connection? connection;

    Device(this.firstname, this.name, this.type, this.os, this.version, this.nearbyUuid);

    /// Schließt die aktuelle Verbindung, bereinigt alle Ressourcen und setzt die Kommunikationsinformationen zurück.
    Future<void> clearConnection() async
    {
        communicationInfo.reset();
        await connection?.close();
        connection = null;
        closeOpenDialogs();
    }

    /// Schließt alle offenen Dialoge, sollten welche geöffnet sein.
    void closeOpenDialogs()
    {
        BuildContext? context = sendRequestDialogKey.currentContext;
        if (isSendRequestDialogOpen && context != null)
        {
            Navigator.of(context).pop();
        }
        isSendRequestDialogOpen = false;

        context = cancelTransportDialogKey.currentContext;
        if (isCancelTransportDialogOpen && context != null)
        {
            Navigator.of(context).pop();
        }
        isCancelTransportDialogOpen = false;
    }

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