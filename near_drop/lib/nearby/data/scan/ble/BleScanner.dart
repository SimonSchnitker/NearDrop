import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:near_drop/tools/UuidHelper.dart';

/// Diese Klasse ist verantwortlich für das Scannen von BLE-Geräten.
class BleScanner
{
    bool _isInitialized = false;
    final StreamController<String> onDeviceSpotted = StreamController<String>.broadcast();

    /// Initialisiert den Scanner.
    Future<void> _initialize() async
    {
        FlutterBluePlus.isScanning.listen((isScanning) {
            print("BleScanner isScanning: $isScanning");
        });

        FlutterBluePlus.scanResults.listen((results) {
            if (results.isEmpty)
            {
                return;
            }

            ScanResult result = results.first;
            Guid? nearbyUuid = result.advertisementData.serviceUuids.firstWhereOrNull((uuid) => uuid.toString().toString().startsWith(UuidHelper.NEARBY_UUID_PREFIX));

            if (nearbyUuid != null)
            {
                onDeviceSpotted.add(nearbyUuid.toString());
            }
        });

        _isInitialized = true;
    }

    /// Startet das Scannen nach BLE-Geräten.
    Future<void> start() async
    {
        if (!_isInitialized)
        {
            await _initialize();
        }

        await FlutterBluePlus.startScan(oneByOne: true);
    }

    /// Stoppt das Scannen nach BLE-Geräten.
    Future<void> stop() async
    {
        await FlutterBluePlus.stopScan();
    }
}