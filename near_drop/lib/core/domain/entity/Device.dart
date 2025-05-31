import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:near_drop/transport/domain/models/Connection.dart';
import '../enums/DeviceType.dart';
import '../enums/ErrorState.dart';
import '../enums/OS.dart';
import '../enums/SuccessState.dart';
import 'CommunicationInfo.dart';

/// Definiert den Aufbau eines Geräts.
class Device extends ChangeNotifier
{
    // Keys und Boolean-Werte für Dialoge, die zum Gerät gehören, um sie von überall aus schließen zu können.
    final GlobalKey<NavigatorState> sendRequestDialogKey = GlobalKey<NavigatorState>();
    final GlobalKey<NavigatorState> cancelTransportDialogKey = GlobalKey<NavigatorState>();
    bool isSendRequestDialogOpen = false;
    bool isCancelTransportDialogOpen = false;

    String firstname;
    String name;
    DeviceType type;
    OS os;
    int version;
    String nearbyUuid;
    final communicationInfo = CommunicationInfo();

    Device(this.firstname, this.name, this.type, this.os, this.version, this.nearbyUuid);

    /// Schließt die aktuelle Verbindung.
    /// Vorsicht: Diese Methode sollte nur aufgerufen werden, wenn bekannt ist, dass die Verbindung aktuell ist. (Bspw. bevor eine neue Verbindung aufgebaut wird.)
    Future<void> closeCurrentConnection() async
    {
        await communicationInfo.closeConnection();
    }

    /// Schließt die aktuelle Verbindung, bereinigt alle Ressourcen und setzt die Kommunikationsinformationen zurück.
    /// Übergeben werden muss das Verbindungs-Objekt, die geschlossen werden soll.
    /// Optional kann ein Erfolgs- oder Fehlerstatus gesetzt werden, um den Abschluss der Verbindung zu signalisieren.
    Future<void> closeConnection({required Connection connection, SuccessState? successState, ErrorState? errorState}) async
    {
        // Prüfen, ob die Verbindung bereits geschlossen ist.
        if (communicationInfo.connection == null)
        {
            return;
        }

        // Wenn die Verbindung nicht mehr aktuell ist, wird nichts unternommen.
        // Dies ist notwendig, um zu verhindern, dass Statusse auf der UI gesetzt werden, wenn alte Verbindungen geschlossen werden.
        if (communicationInfo.connection?.connectionId != connection.connectionId)
        {
            return;
        }

        // Optional: Setzen des Erfolgs- oder Fehlerstatus.
        if (successState != null)
        {
            communicationInfo.setSuccessState(successState);
        }
        else if (errorState != null)
        {
            communicationInfo.setErrorState(errorState);
        }

        communicationInfo.reset();
        await communicationInfo.closeConnection();
    }

    /// Schließt alle offenen Dialoge, sollten welche geöffnet sein.
    void closeOpenDialogs()
    {
        return;

        BuildContext? context = sendRequestDialogKey.currentContext;
        if (isSendRequestDialogOpen && context != null)
        {
            Navigator.of(context).maybePop();
        }
        isSendRequestDialogOpen = false;

        context = cancelTransportDialogKey.currentContext;
        if (isCancelTransportDialogOpen && context != null)
        {
            Navigator.of(context).maybePop();
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