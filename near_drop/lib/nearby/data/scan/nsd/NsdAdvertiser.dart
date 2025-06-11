import 'dart:typed_data';
import 'package:near_drop/nearby/data/scan/nsd/NsdBase.dart';
import 'package:nsd/nsd.dart';
import '../../../../Runtime.dart';

/// Diese Klasse ist verantwortlich für das Aussenden von NSD-Werbung.
class NsdAdvertiser extends NsdBase
{
    Registration? registration;

    /// Registriert den Service bei NSD.
    Future<void> start() async
    {
        registration = await register(Service(
            name: Runtime.appName,
            type: NsdBase.serviceType,
            port: 56000,
            txt: {
                "firstname": Uint8List.fromList(Runtime.firstname.codeUnits),
                "deviceName": Uint8List.fromList(Runtime.deviceName.codeUnits),
                "deviceType": Uint8List.fromList(Runtime.deviceType.name.codeUnits),
                "os": Uint8List.fromList(Runtime.os.name.codeUnits),
                "version": Uint8List.fromList(Runtime.version.toString().codeUnits),
                "nearbyUuid": Uint8List.fromList(Runtime.nearbyUuid.codeUnits),
            }
        ));
    }

    /// Entfernt die Registrierung des Services bei NSD.
    Future<void> stop() async
    {
        if (registration != null)
        {
            await unregister(registration!);
            registration = null;
        }
    }
}