import 'dart:async';
import 'dart:typed_data';
import 'package:near_drop/nearby/data/event_args/NsdDeviceSpottedEventArgs.dart';
import 'package:near_drop/nearby/data/scan/nsd/NsdBase.dart';
import 'package:nsd/nsd.dart';
import '../../../../Runtime.dart';

/// Diese Klasse ist verantwortlich für das Scannen von Diensten über NSD.
class NsdScanner extends NsdBase
{
    final StreamController<NsdDeviceSpottedEventArgs> onDeviceSpotted = StreamController<NsdDeviceSpottedEventArgs>.broadcast();
    Discovery? _discovery;

    /// Startet den NSD-Scanner und beginnt mit dem Scannen nach Diensten.
    Future<void> start() async
    {
        _discovery = await startDiscovery(NsdBase.serviceType);
        _discovery?.addServiceListener((service, status) {
            if (status == ServiceStatus.found)
            {
                // Wenn der gefundene Service nicht zu unserer App gehört, ignorieren
                String? serviceName = service.name;
                if (serviceName == null)
                {
                    return;
                }

                // Wenn der gefundene Service nicht mit dem App-Namen beginnt, ignorieren
                // Manchmal wird hinter dem Namen bspw. eine (2) angehängt, wenn der Name bereits existiert.
                if (!serviceName.startsWith(Runtime.appName))
                {
                    return;
                }

                // Wenn der gefundene Service keinen Port hat, ignorieren
                if (service.port == null)
                {
                    return;
                }

                // Wenn der gefundene Service sowohl keine Adressen als auch keinen Host hat, ignorieren
                if (service.addresses == null && service.host == null)
                {
                    return;
                }

                // Wenn der gefundene Service keine Attribute hat, ignorieren
                Map<String, Uint8List?>? attributes = service.txt;
                if (attributes == null || attributes.isEmpty)
                {
                    return;
                }

                // Wenn das Attribut "nearbyUuid" nicht vorhanden ist, ignorieren
                Uint8List? nearbyUuidBytes = attributes["nearbyUuid"];
                if (nearbyUuidBytes == null)
                {
                    return;
                }

                String nearbyUuid = String.fromCharCodes(nearbyUuidBytes);
                onDeviceSpotted.add(NsdDeviceSpottedEventArgs(port: service.port!, nearbyUuid: nearbyUuid, host: service.host, addresses: service.addresses));
            }
        });
    }

    /// Stoppt den NSD-Scanner und beendet das Scannen nach Diensten.
    Future<void> stop() async
    {
        if (_discovery != null)
        {
            await stopDiscovery(_discovery!);
            _discovery = null;
        }
    }
}