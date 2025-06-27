import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:near_drop/nearby/data/scan/nsd/NsdBase.dart';
import 'package:nsd/nsd.dart';
import 'package:permission_handler/permission_handler.dart';

/// Hilfsklasse zur Verwaltung von Berechtigungen.
class PermissionHelper
{
    /// Prüft, ob der Benutzer die Berechtigung erteilt hat, Geräte in der Nähe zu erkennen und zu verbinden.
    static Future<bool> hasNearbyPermission() async
    {
        if (Platform.isAndroid)
        {
            final androidInfo = await DeviceInfoPlugin().androidInfo;

            if (androidInfo.version.sdkInt >= 31) // Android 12 und höher
            {
                return await Permission.bluetoothScan.isGranted &&
                       await Permission.bluetoothAdvertise.isGranted &&
                       await Permission.bluetoothConnect.isGranted;
            }
            else // Für Android 11 und niedriger wird für Bluetooth die Standortberechtigung benötigt
            {
                return await Permission.location.isGranted;
            }
        }
        else if (Platform.isIOS)
        {
            return await Permission.bluetooth.isGranted;
        }

        return true; // Für Windows und macOS ist keine Berechtigung erforderlich
    }

    /// Fordert die Berechtigung an, Geräte in der Nähe zu erkennen und zu verbinden.
    static Future<bool> requestNearbyPermission() async
    {
        if (Platform.isAndroid)
        {
            final androidInfo = await DeviceInfoPlugin().androidInfo;

            if (androidInfo.version.sdkInt >= 31) // Android 12 und höher
            {
                Map<Permission, PermissionStatus> statuses = await [
                    Permission.bluetoothScan,
                    Permission.bluetoothAdvertise,
                    Permission.bluetoothConnect
                ].request();

                for (var status in statuses.values)
                {
                    if (status != PermissionStatus.granted)
                    {
                        return false;
                    }
                }

                return true;
            }
            else // Für Android 11 und niedriger wird für Bluetooth die Standortberechtigung benötigt
            {
                return await Permission.location.request() == PermissionStatus.granted;
            }
        }
        else if (Platform.isIOS)
        {
            return await Permission.bluetooth.request() == PermissionStatus.granted;
        }

        return true; // Für Windows und macOS ist keine Berechtigung erforderlich
    }

    /// Fordert die Berechtigung für den Zugriff auf das lokale Netzwerk auf iOS an.
    static Future<void> requestIOSLocalNetworkPermission() async
    {
        if (Platform.isIOS)
        {
            try
            {
                // Damit der Berechtigungsdialog angezeigt wird, muss eine Netzwerkentdeckung gestartet werden
                // Daher wird sie hier temporär gestartet und danach wieder gestoppt.
                final discovery = await startDiscovery(NsdBase.serviceType);
                await stopDiscovery(discovery);
            }
            catch (e)
            {
                // Ignorieren
            }
        }
    }

    /// Prüft, ob auf den externen Speicher außerhalb der App zugegriffen werden kann.
    /// Dies wird nur unter Android 10 oder nieriger benötigt.
    static Future<bool> hasExternalStoragePermission() async
    {
        if (Platform.isAndroid)
        {
            final androidInfo = await DeviceInfoPlugin().androidInfo;
            if (androidInfo.version.sdkInt <= 29)
            {
                return await Permission.storage.isGranted;
            }
        }

        return true;
    }

    /// Fordert die Berechtigung für den Zugriff auf den externen Speicher außerhalb der App an.
    static Future<bool> requestAndroid10AndBelowExternalStoragePermission() async
    {
        if (Platform.isAndroid)
        {
            final androidInfo = await DeviceInfoPlugin().androidInfo;
            if (androidInfo.version.sdkInt <= 29)
            {
                return await Permission.storage.request() == PermissionStatus.granted;
            }
        }

        return true;
    }
}