import 'package:near_drop/nearby/data/scan/ble/BleAdvertiser.dart';
import 'package:near_drop/nearby/data/scan/ble/BleScanner.dart';

class NearbyController
{
    final BleScanner _bleScanner;
    final BleAdvertiser _bleAdvertiser;

    NearbyController(this._bleScanner, this._bleAdvertiser)
    {
        _bleScanner.onDeviceSpotted.stream.listen(onBleDeviceSpotted);
    }

    void onBleDeviceSpotted(String nearbyUuid)
    {
        print("Nearby device spotted: $nearbyUuid");
    }

    /// Startet die BLE-Scanner- und Werbeträgerdienste.
    Future<void> startBleServices() async
    {
        await _bleScanner.start();
        await _bleAdvertiser.start();
    }

    /// Stoppt die BLE-Scanner- und Werbeträgerdienste.
    Future<void> stopBleServices() async
    {
        await _bleScanner.stop();
        await _bleAdvertiser.stop();
    }
}