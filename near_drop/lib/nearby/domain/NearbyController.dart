import 'package:near_drop/nearby/data/NearbyGateway.dart';
import 'package:near_drop/nearby/data/scan/ble/BleAdvertiser.dart';
import 'package:near_drop/nearby/data/scan/ble/BleScanner.dart';
import 'package:near_drop/nearby/domain/NearbyDevicesContainer.dart';
import '../../core/entity/Device.dart';

class NearbyController
{
    // Die Zeit, die mindestens vergangen sein muss, bevor wir ein Gerät erneut informieren. Dies dient dazu, dass wenn
    // sich beide Geräte gleichzeitig finden, sie sich nicht versehentlich mehrmals informieren.
    // Ebenfalls kann das Szenario eintreten, dass Gerät B die App schließt und wieder öffnet. Es könnte passieren,
    // dass Gerät A das nicht mitbekommt. Gerät B erkennt dann wie gewohnt Gerät A und sendet seine Gerätedaten. Gerät A sieht dann anhand
    // des Zeitstempels, dass es einige Zeit her ist, dass es Gerät B informiert hat und sendet erneut seine Gerätedaten.
    final Duration minInformedInterval = Duration(seconds: 3);

    final BleScanner _bleScanner;
    final BleAdvertiser _bleAdvertiser;
    final NearbyGateway _nearbyGateway;

    // In dieser Liste werden die UUIDs der Geräte gespeichert, denen wir bereits unsere Gerätedaten gesendet haben und wann.
    final Map<String, DateTime> _informedDevices = {};

    // In dieser Liste werden die UUIDs der Geräte gespeichert, die wir gerade informieren.
    final List<String> _currentlyInformingDevices = [];

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

        // Wenn wir das Gerät bereits gefunden haben oder es gerade informieren, abbrechen
        if (await NearbyDevicesContainer.containsUuid(nearbyUuid) || _currentlyInformingDevices.contains(nearbyUuid))
        {
            return;
        }

        await _informDevice(nearbyUuid);
    }

    Future<void> onDeviceDataReceived(Device device) async
    {
        print("Device data received: ${device.firstname}, ${device.name}, ${device.type}, ${device.os}, ${device.version}");
        await NearbyDevicesContainer.addIfNotContains(device);

        // Wenn wir ihn gerade informieren, abbrechen
        if (_currentlyInformingDevices.contains(device.nearbyUuid))
        {
            return;
        }

        // Wenn wir ihn erst vor kurzem informiert haben, abbrechen
        DateTime? lastInformed = _informedDevices[device.nearbyUuid];
        if (lastInformed == null || DateTime.now().difference(lastInformed) < Duration(seconds: 3))
        {
            return;
        }

        await _informDevice(device.nearbyUuid);
    }

    Future<void> _informDevice(String nearbyUuid) async
    {
        // Merken, dass wir das Gerät gerade informieren
        _currentlyInformingDevices.add(nearbyUuid);

        bool sent = await _nearbyGateway.sendDeviceData(nearbyUuid);
        if (sent)
        {
            // Speichern, wann wir das Gerät informiert haben
            _informedDevices[nearbyUuid] = DateTime.now();
        }

        // Gerät aus der Liste der aktuell informierten Geräte entfernen
        _currentlyInformingDevices.remove(nearbyUuid);
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