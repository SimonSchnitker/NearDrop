import 'dart:async';
import 'package:near_drop/core/Version.dart';
import 'package:near_drop/tools/DeviceHelper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/domain/enums/DeviceType.dart';
import 'core/domain/enums/OS.dart';
import 'main.dart';

/// Stellt Laufzeit-Daten bereit.
class Runtime
{
    static const String nearDropWebsiteUrl = "https://neardrop.app";
    static const String privacyPolicyUrl = "https://neardrop.app/privacy";
    static const String imprintUrl = "https://neardrop.app/imprint";
    static const String termsOfUseUrl = "https://neardrop.app/termsofuse";
    static const String androidAppUrl = "https://play.google.com/store/apps/details?id=de.neardrop.app";
    static const String iosAppUrl = "https://apps.apple.com/de/app/near-drop-file-sharing/id6747198778";
    static const String windowsAppUrl = "https://apps.microsoft.com/detail/9p7czj2vktt7";
    static const String appName = "Near Drop";
    static final appVersion = Version(1, 0, 1);
    static final int privacyPolicyVersion = 1;
    static final int termsOfUseVersion = 1;

    static StreamController<String> onFirstnameChanged = StreamController<String>.broadcast();

    static int deviceId = 0;
    static String firstname = "";
    static String deviceName = "";
    static DeviceType deviceType = DeviceType.unknown;
    static OS os = OS.unknown;
    static String nearbyUuid = "";

    // Unser Supabase-Channel, auf dem wir Nachrichten empfangen.
    static late RealtimeChannel realtimeChannel;

    /// Lädt die statischen Laufzeitdaten des Geräts.
    static Future<void> initializeDeviceData() async
    {
        try
        {
            deviceName = await DeviceHelper.getDeviceName();
        }
        catch (e)
        {
            deviceName = "???";
        }

        try
        {
            deviceType = await DeviceHelper.getDeviceType();
        }
        catch (e)
        {
            deviceType = DeviceType.unknown;
        }

        os = DeviceHelper.getOS();
    }

    /// Initialisiert unseren Supabase-Realtime-Channel, auf dem wir Nachrichten empfangen.
    static Future<bool> initializeChannel() async
    {
        Completer<bool> completer = Completer<bool>();

        realtimeChannel = Supabase.instance.client.channel(nearbyUuid);
        realtimeChannel.subscribe((status, o) {
           dprint("Supabase RealtimeChannel status changed: $status");

           if (completer.isCompleted)
           {
               return;
           }

           if (status == RealtimeSubscribeStatus.subscribed)
           {
               completer.complete(true);
           }
           else
           {
               completer.complete(false);
           }
        });

        return await completer.future;
    }

    /// Beendet das Lauschen auf Nachrichten an unserem Channel.
    static Future<void> unsubscribeChannel() async
    {
        realtimeChannel.unsubscribe();
    }
}