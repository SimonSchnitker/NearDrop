import 'dart:async';
import 'dart:typed_data';
import 'package:near_drop/core/domain/entity/Device.dart';
import 'package:near_drop/core/domain/enums/DeviceType.dart';
import 'package:near_drop/nearby/data/scan/nsd/NsdBase.dart';
import 'package:nsd/nsd.dart';
import '../../../../core/domain/enums/OS.dart';

/// Diese Klasse ist verantwortlich für das Scannen von Diensten über NSD.
class NsdScanner extends NsdBase
{
    final StreamController<Device> onDeviceFound = StreamController<Device>.broadcast();
    Discovery? _discovery;

    /// Startet den NSD-Scanner und beginnt mit dem Scannen nach Diensten.
    Future<void> start() async
    {
        _discovery = await startDiscovery(NsdBase.serviceType);
        _discovery?.addServiceListener((service, status) {
            if (status == ServiceStatus.found)
            {
                Map<String, Uint8List?>? attributes = service.txt;
                if (attributes == null || attributes.isEmpty)
                {
                    return;
                }

                Uint8List? firstnameBytes = attributes["firstname"];
                Uint8List? deviceNameBytes = attributes["deviceName"];
                Uint8List? deviceTypeBytes = attributes["deviceType"];
                Uint8List? osBytes = attributes["os"];
                Uint8List? versionBytes = attributes["version"];
                Uint8List? nearbyUuidBytes = attributes["nearbyUuid"];

                if (firstnameBytes == null || deviceNameBytes == null || deviceTypeBytes == null ||
                    osBytes == null || versionBytes == null || nearbyUuidBytes == null)
                {
                    return;
                }

                final device = Device(
                    String.fromCharCodes(firstnameBytes),
                    String.fromCharCodes(deviceNameBytes),
                    DeviceType.values.byName(String.fromCharCodes(deviceTypeBytes)),
                    OS.values.byName(String.fromCharCodes(osBytes)),
                    int.parse(String.fromCharCodes(versionBytes)),
                    String.fromCharCodes(nearbyUuidBytes)
                );

                onDeviceFound.add(device);
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