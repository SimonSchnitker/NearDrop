import 'package:near_drop/nearby/data/NearbyGateway.dart';
import 'package:near_drop/nearby/data/scan/ble/BleAdvertiser.dart';
import 'package:near_drop/nearby/data/scan/ble/BleScanner.dart';
import 'package:near_drop/nearby/domain/NearbyDevicesContainer.dart';

import '../../core/entity/Device.dart';

class NearbyController
{
    final BleScanner _bleScanner;
    final BleAdvertiser _bleAdvertiser;
    final NearbyGateway _nearbyGateway;

    // In dieser Liste werden die UUIDs der Geräte gespeichert, denen wir bereits unsere Gerätedaten gesendet haben.
    final List<String> _informedDevices = [];

    NearbyController(this._bleScanner, this._bleAdvertiser, this._nearbyGateway)
    {
        _bleScanner.onDeviceSpotted.stream.listen(onBleDeviceSpotted);
        _nearbyGateway.onDeviceDataReceived.stream.listen(onDeviceDataReceived);

        // Gerät aus informierten Geräten entfernen, wenn es nicht mehr in der Nähe ist, damit wir es erneut finden können
        NearbyDevicesContainer.onRemoved.stream.listen((device) async {
            _informedDevices.remove(device.nearbyUuid);
        });
    }

    Future<void> onBleDeviceSpotted(String nearbyUuid) async
    {
        print("Nearby device spotted: $nearbyUuid");

        if (await NearbyDevicesContainer.containsUuid(nearbyUuid) || _informedDevices.contains(nearbyUuid))
        {
            return;
        }

        _informedDevices.add(nearbyUuid);

        bool sent = await _nearbyGateway.sendDeviceData(nearbyUuid);
        if (!sent)
        {
            _informedDevices.remove(nearbyUuid);
        }
    }

    Future<void> onDeviceDataReceived(Device device) async
    {
        print("Device data received: ${device.firstname}, ${device.name}, ${device.type}, ${device.os}, ${device.version}");
        await NearbyDevicesContainer.addIfNotContains(device);

        // Unsere Gerätedaten zurücksenden, wenn wir sie noch nicht gesendet haben
        if (!_informedDevices.contains(device.nearbyUuid))
        {
            _informedDevices.add(device.nearbyUuid);
            bool sent = await _nearbyGateway.sendDeviceData(device.nearbyUuid);
            if (!sent)
            {
                _informedDevices.remove(device.nearbyUuid);
            }
        }
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

    /// Startet das Lauschen auf Gerätedaten.
    void startListeningForDeviceData()
    {
        _nearbyGateway.startListeningForDeviceData();
    }
}