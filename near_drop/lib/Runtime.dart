import 'package:near_drop/core/enums/DeviceType.dart';
import 'package:near_drop/core/enums/OS.dart';

/// Stellt Laufzeit-Daten bereit.
class Runtime
{
    static const int version = 1;
    static const Map<int, String> versionMap = {
        1: "1.0.0",
    };

    static bool deviceDataLoaded = false;
    static int deviceId = 0;
    static String firstname = "";
    static String deviceName = "";
    static DeviceType deviceType = DeviceType.unknown;
    static OS os = OS.unknown;
    static String nearbyUuid = "";

    static String getVersionString()
    {
        if (versionMap.containsKey(version))
        {
            return versionMap[version]!;
        }

        return version.toString();
    }
}