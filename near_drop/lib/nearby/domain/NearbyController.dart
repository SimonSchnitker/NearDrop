import 'dart:async';
import 'package:near_drop/nearby/data/NearbyGateway.dart';
import 'package:near_drop/nearby/data/scan/ble/BleAdvertiser.dart';
import 'package:near_drop/nearby/data/scan/ble/BleScanner.dart';
import 'package:near_drop/nearby/domain/NearbyDevicesContainer.dart';

import '../../core/domain/entity/Device.dart';

/// Steuert das Suchen nach Geräten in der Nähe und den Austausch von Gerätedaten.
class NearbyController
{
    final BleScanner _bleScanner;
    final BleAdvertiser _bleAdvertiser;
    final NearbyGateway _nearbyGateway;

    final StreamController<bool> onBleAdvertiserStatusChanged = StreamController.broadcast();
    final StreamController<bool> onBleScannerStatusChanged = StreamController.broadcast();

    final Duration waitingForDeviceDataTimeout = Duration(seconds: 4);
    final Map<String, DateTime> _requestingDevices = {};

    NearbyController(this._bleScanner, this._bleAdvertiser, this._nearbyGateway)
    {
        _bleScanner.onDeviceSpotted.stream.listen(onBleDeviceSpotted);
        _nearbyGateway.onDeviceDataReceived.stream.listen(onDeviceDataReceived);
        _nearbyGateway.onDeviceRequestReceived.stream.listen(onDeviceRequestReceived);

        // Events vom BleAdvertiser und BleScanner zum ViewModel weiterleiten
        _bleAdvertiser.onAdvertisingStatusChanged.stream.listen((status) {
            onBleAdvertiserStatusChanged.add(status);
        });
        _bleScanner.onScanningStatusChanged.stream.listen((status) {
            onBleScannerStatusChanged.add(status);
        });
    }

    /// Überprüft, ob auf die Gerätedaten eines Geräts gewartet wird.
    bool _isWaitingForDeviceData(String nearbyUuid)
    {
        DateTime? requestTime = _requestingDevices[nearbyUuid];
        if (requestTime == null)
        {
            return false;
        }

        Duration timeSinceRequest = DateTime.now().difference(requestTime);
        if (timeSinceRequest < waitingForDeviceDataTimeout)
        {
            return true;
        }

        return false;
    }

    /// Wird aufgerufen, wenn ein BLE-Gerät entdeckt wird.
    Future<void> onBleDeviceSpotted(String nearbyUuid) async
    {
        // Wenn wir das Gerät bereits kennen oder seine Gerätedaten gerade anfordern, dann abbrechen.
        if (await NearbyDevicesContainer.containsUuid(nearbyUuid) || _isWaitingForDeviceData(nearbyUuid))
        {
            return;
        }

        // Ansonten fordern wir die Gerätedaten an.
        await requestDeviceData(nearbyUuid);
    }

    /// Fordert die Gerätedaten eines anderen Geräts an und speichert den Zeitpunkt der Anfrage.
    Future<void> requestDeviceData(String nearbyUuid) async
    {
        _requestingDevices[nearbyUuid] = DateTime.now();
        await _nearbyGateway.sendDeviceDataRequest(nearbyUuid);
    }

    /// Wird aufgerufen, wenn Gerätedaten empfangen wurden.
    Future<void> onDeviceDataReceived(Device device) async
    {
        // Wenn wir die Gerätedaten nicht angefordert haben, dann abbrechen.
        if (!_isWaitingForDeviceData(device.nearbyUuid))
        {
            return;
        }

        await NearbyDevicesContainer.addIfNotContains(device);
    }

    /// Wird aufgerufen, wenn eine Anfrage für Gerätedaten empfangen wird.
    Future<void> onDeviceRequestReceived(String nearbyUuid) async
    {
        await _nearbyGateway.sendDeviceData(nearbyUuid);

        // Wenn wir das Gerät bereits kennen oder seine Gerätedaten gerade anfordern, dann abbrechen.
        if (await NearbyDevicesContainer.containsUuid(nearbyUuid) || _isWaitingForDeviceData(nearbyUuid))
        {
            return;
        }

        // Ansonsten fordern wir auch seine Gerätedaten an.
        await requestDeviceData(nearbyUuid);
    }

    /// Startet die BLE-Scanner- und Werbeträgerdienste.
    Future<void> startBleServices() async
    {
        try
        {
            await _bleScanner.start();
        }
        catch (e)
        {
            print("BLE-Scanner konnte nicht gestartet werden: $e");
        }

        try
        {
            await _bleAdvertiser.start();
        }
        catch (e)
        {
            print("BLE-Advertiser konnte nicht gestartet werden: $e");
        }
    }

    /// Stoppt die BLE-Scanner- und Werbeträgerdienste.
    Future<void> stopBleServices() async
    {
        try
        {
            await _bleScanner.stop();
        }
        catch (e)
        {
            print("BLE-Scanner konnte nicht gestoppt werden: $e");
        }

        try
        {
            await _bleAdvertiser.stop();
        }
        catch (e)
        {
            print("BLE-Advertiser konnte nicht gestoppt werden: $e");
        }
    }

    /// Startet das Lauschen auf Gerätedaten.
    void startListeningForDeviceData()
    {
        _nearbyGateway.startListeningForDeviceData();
    }
}