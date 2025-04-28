import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:near_drop/device/data/DeviceGateway.dart';
import 'package:near_drop/settings/domain/SettingsController.dart';
import 'package:near_drop/tools/UuidHelper.dart';
import '../../Runtime.dart';
import '../../core/entity/Device.dart';
import '../../core/enums/DeviceType.dart';
import '../../core/enums/OS.dart';
import '../../settings/domain/Setting.dart';

/// Geschäftslogik für Gerätedaten.
class DeviceController
{
    final DeviceGateway _deviceGateway;
    final SettingsController _settingsController;
    final _deviceInfoPlugin = DeviceInfoPlugin();

    // Einstellungen, die in den SharedPreferences gespeichert werden
    static final deviceIdSetting = Setting("device_id", int);
    static final firstnameSetting = Setting("firstname", String);
    static final deviceNameSetting = Setting("device_name", String);
    static final versionSetting = Setting("version", int);
    static final nearbyUuidSetting = Setting("nearby_uuid", String);
    static final nearbyUuidCreationSetting = Setting("nearby_uuid_creation", String);

    DeviceController(this._deviceGateway, this._settingsController);

    /// Alt
    Future<bool> loadThisDevice() async
    {
        try
        {
            int? id = await _settingsController.get(deviceIdSetting);
            String? firstname = await _settingsController.get(firstnameSetting);
            String? deviceName = await _settingsController.get(deviceNameSetting);
            int? version = await _settingsController.get(versionSetting);
            String? nearbyUuid = await _settingsController.get(nearbyUuidSetting);

            if (id == null || firstname == null || deviceName == null || nearbyUuid == null)
            {
                return false;
            }

            String currentDeviceName = await _getDeviceName();

            // Wenn während die App geschlossen war, sich der Name des Geräts oder die Version geändert haben, werden diese Daten in der Datenbank aktualisiert
            if (deviceName != currentDeviceName || version != Runtime.version)
            {
                // Wenn der Name nicht übereinstimmt, dann wird der Name in der Datenbank aktualisiert
                try
                {
                    await _deviceGateway.updateDevice(deviceName: currentDeviceName, version: Runtime.version);
                    await _settingsController.set(deviceNameSetting, currentDeviceName);
                    await _settingsController.set(versionSetting, Runtime.version);
                    deviceName = currentDeviceName;
                }
                catch (e)
                {
                    print("Fehler beim Aktualisieren des Geräts: $e");
                }
            }

            Runtime.deviceId = id;
            Runtime.firstname = firstname;
            Runtime.deviceName = deviceName!;
            Runtime.deviceType = await _getDeviceType();
            Runtime.os = _getOS();
            Runtime.nearbyUuid = nearbyUuid;
            Runtime.deviceDataLoaded = true;
            return true;
        }
        catch (e)
        {
            print("Fehler beim Laden der Gerätedaten: $e");
            return false;
        }
    }

    /// Lädt die eigenen Gerätedaten und aktualisiert ggf. die Nearby-UUID.
    Future<void> loadThis() async
    {
        String? firstname = await _settingsController.get(firstnameSetting);
        if (firstname == null)
        {
            throw Exception("Firstname ist null.");
        }

        String? nearbyUuid = await _settingsController.get(nearbyUuidSetting);
        String? nearbyUuidCreation = await _settingsController.get(nearbyUuidCreationSetting);

        if (nearbyUuid == null || nearbyUuidCreation == null)
        {
            // Wenn die UUID-Daten nicht vorhanden sind, wird eine neue UUID generiert
            await updateNearbyUuid();
        }
        else
        {
            DateTime? creationDate = DateTime.parse(nearbyUuidCreation);

            if (DateTime.now().difference(creationDate).inMinutes > 10)
            {
                // Wenn die UUID älter als 10 Minuten ist, wird eine neue UUID generiert
                await updateNearbyUuid();
            }
            else
            {
                Runtime.nearbyUuid = nearbyUuid;
            }
        }

        bool realtimeChannelInitialized = await Runtime.initializeChannel();
        if (!realtimeChannelInitialized)
        {
            throw Exception("RealtimeChannel konnte nicht initialisiert werden");
        }

        // Laufzeitdaten setzen
        Runtime.firstname = firstname;
        Runtime.deviceName = await _getDeviceName();
        Runtime.deviceType = await _getDeviceType();
        Runtime.os = _getOS();
        Runtime.deviceDataLoaded = true;
    }

    /// Aktualisiert die Nearby-UUID in der Supabase-Datenbank und speichert sie in den SharedPreferences.
    Future<void> updateNearbyUuid() async
    {
        String uuid = await _deviceGateway.updateNearbyUuid();
        await _settingsController.set(nearbyUuidSetting, uuid);
        await _settingsController.set(nearbyUuidCreationSetting, DateTime.now().toString());
        Runtime.nearbyUuid = uuid;
    }

    /// Erstellt ein neues Gerät in der Supabase-Datenbank und speichert die Werte in den SharedPreferences.
    Future<void> createDevice(String firstname) async
    {
        String deviceName = await _getDeviceName();
        DeviceType deviceType = await _getDeviceType();
        OS os = _getOS();
        String nearbyUuid = UuidHelper.getRandomDeviceUUID();

        var (int id, Device device) = await _deviceGateway.createDevice(firstname, deviceName, deviceType, os, Runtime.version, nearbyUuid);
        
        // Daten in den SharedPreferences speichern
        await _settingsController.set(deviceIdSetting, id);
        await _settingsController.set(firstnameSetting, firstname);
        await _settingsController.set(deviceNameSetting, deviceName);
        await _settingsController.set(versionSetting, Runtime.version);
        await _settingsController.set(nearbyUuidSetting, nearbyUuid);

        Runtime.deviceId = id;
        Runtime.firstname = firstname;
        Runtime.deviceName = deviceName;
        Runtime.deviceType = deviceType;
        Runtime.os = os;
        Runtime.nearbyUuid = nearbyUuid;
    }

    /// Ermittelt den internen Namen dieses Geräts.
    /// Der Name wird ggf. gekürzt.
    Future<String> _getDeviceName() async
    {
        if (Platform.isAndroid)
        {
            final deviceInfo = await _deviceInfoPlugin.androidInfo;
            return deviceInfo.model;
        }
        else if (Platform.isIOS)
        {
            final deviceInfo = await _deviceInfoPlugin.iosInfo;
            String modelName = deviceInfo.modelName;

            if (modelName.contains("("))
            {
                return modelName.substring(0, modelName.indexOf("(")).trimRight();
            }

            return deviceInfo.modelName;
        }
        else if (Platform.isWindows)
        {
            //final deviceInfo = await _deviceInfoPlugin.windowsInfo;
            //return deviceInfo.computerName;
            return "Windows";
        }
        else if (Platform.isMacOS)
        {
            final deviceInfo = await _deviceInfoPlugin.macOsInfo;
            String modelName = deviceInfo.modelName;

            if (modelName.contains("("))
            {
                return modelName.substring(0, modelName.indexOf("(")).trimRight();
            }

            return deviceInfo.modelName;
        }
        else if (Platform.isLinux)
        {
            final deviceInfo = await _deviceInfoPlugin.linuxInfo;
            return deviceInfo.name;
        }

        return "";
    }

    /// Ermittelt den Typ dieses Geräts.
    Future<DeviceType> _getDeviceType() async
    {
        if (Platform.isAndroid)
        {
            /*
            if (PlatformDispatcher.instance.views.isNotEmpty && PlatformDispatcher.instance.views.first.physicalSize.shortestSide >= 600)
            {
                return DeviceType.Tablet;
            }
             */

            return DeviceType.phone;
        }
        else if (Platform.isIOS)
        {
            final deviceInfo = await _deviceInfoPlugin.iosInfo;
            if (deviceInfo.modelName.toLowerCase().startsWith("ipad"))
            {
                return DeviceType.tablet;
            }
            return DeviceType.phone;
        }
        else if (Platform.isWindows)
        {
            return DeviceType.pc;
        }
        else if (Platform.isMacOS)
        {
            final deviceInfo = await _deviceInfoPlugin.macOsInfo;
            if (deviceInfo.modelName.toLowerCase().startsWith("imac"))
            {
                return DeviceType.pc;
            }
            return DeviceType.laptop;
        }
        else if (Platform.isLinux)
        {
            return DeviceType.pc;
        }

        return DeviceType.unknown;
    }

    /// Ermittelt das Betriebssystem des dieses Geräts.
    OS _getOS()
    {
        if (Platform.isAndroid)
        {
            return OS.android;
        }
        else if (Platform.isIOS)
        {
            return OS.ios;
        }
        else if (Platform.isWindows)
        {
            return OS.windows;
        }
        else if (Platform.isMacOS)
        {
            return OS.macos;
        }
        else if (Platform.isLinux)
        {
            return OS.linux;
        }

        return OS.unknown;
    }
}