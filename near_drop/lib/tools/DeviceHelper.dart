import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../core/enums/DeviceType.dart';
import '../core/enums/OS.dart';

/// Hilfsklasse für Geräteinformationen.
class DeviceHelper
{
    static final _deviceInfoPlugin = DeviceInfoPlugin();

    /// Ermittelt den internen Namen dieses Geräts.
    /// Der Name wird ggf. gekürzt.
    static Future<String> getDeviceName() async
    {
        if (Platform.isAndroid)
        {
            final deviceInfo = await DeviceInfoPlugin().androidInfo;
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
    static Future<DeviceType> getDeviceType() async
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
    static OS getOS()
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