import 'dart:async';
import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:near_drop/Runtime.dart';

import '../../../../main.dart';

/// Diese Klasse ist verantwortlich für das Aussenden von BLE-Werbung.
class BleAdvertiser
{
    bool _isInitialized = false;
    final StreamController<bool> onAdvertisingStatusChanged = StreamController.broadcast();

    /// Initialisiert den BLE-Werbeträger.
    Future<void> _initialize() async
    {
        await BlePeripheral.initialize();

        BlePeripheral.setAdvertisingStatusUpdateCallback((bool advertising, String? error) {
            dprint("BleAdvertiser status changed. AdvertisingStatus: $advertising, Error: $error");
            onAdvertisingStatusChanged.add(advertising);
        });

        _isInitialized = true;
    }

    /// Startet das Aussenden von BLE-Werbung.
    Future<void> start() async
    {
        if (!_isInitialized)
        {
            _initialize();
        }

        await BlePeripheral.clearServices();
        await BlePeripheral.addService(
            BleService(
                uuid: Runtime.nearbyUuid,
                primary: true,
                characteristics: []
            )
        );

        await BlePeripheral.startAdvertising(services: [Runtime.nearbyUuid]);
    }

    /// Stoppt das Aussenden von BLE-Werbung.
    Future<void> stop() async
    {
        if (!_isInitialized)
        {
            return;
        }

        await BlePeripheral.stopAdvertising();
    }
}