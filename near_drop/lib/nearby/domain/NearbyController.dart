import 'dart:async';
import 'package:near_drop/nearby/data/LocalNetworkGateway.dart';
import 'package:near_drop/nearby/data/SupabaseDeviceGateway.dart';
import 'package:near_drop/nearby/data/event_args/NsdDeviceSpottedEventArgs.dart';
import 'package:near_drop/nearby/data/scan/ble/BleAdvertiser.dart';
import 'package:near_drop/nearby/data/scan/ble/BleScanner.dart';
import 'package:near_drop/nearby/data/scan/nsd/NsdAdvertiser.dart';
import 'package:near_drop/nearby/data/scan/nsd/NsdScanner.dart';
import 'package:near_drop/nearby/domain/NearbyDevicesContainer.dart';
import '../../Runtime.dart';
import '../../core/domain/entity/Device.dart';

/// Steuert das Suchen nach Geräten in der Nähe und den Austausch von Gerätedaten.
class NearbyController
{
    final BleScanner _bleScanner;
    final BleAdvertiser _bleAdvertiser;
    final NsdScanner _nsdScanner;
    final NsdAdvertiser _nsdAdvertiser;
    final SupabaseDeviceGateway _supabaseDeviceGateway;
    final LocalNetworkGateway _localNetworkGateway;

    final StreamController<bool> onBleAdvertiserStatusChanged = StreamController.broadcast();
    final StreamController<bool> onBleScannerStatusChanged = StreamController.broadcast();

    final Duration waitingForDeviceDataTimeout = Duration(seconds: 4);
    final Map<String, DateTime> _requestingDevices = {};
    int _localNetworkPort = -1;

    NearbyController(this._bleScanner, this._bleAdvertiser, this._nsdScanner, this._nsdAdvertiser, this._supabaseDeviceGateway, this._localNetworkGateway)
    {
        // Warten auf Ereignisse über Supabase
        _supabaseDeviceGateway.onDeviceDataReceived.stream.listen(onDeviceDataReceived);
        _supabaseDeviceGateway.onDeviceRequestReceived.stream.listen(onDeviceRequestReceived);

        // Warten auf Ereignisse über den lokalen Netzwerk-Gateway
        _localNetworkGateway.onDeviceResolved.stream.listen(_onNetworkDeviceResolved);

        // Warten auf Ereignisse über den NSD-Scanner und den BLE-Scanner
        _nsdScanner.onDeviceSpotted.stream.listen(_onNsdDeviceSpotted);
        _bleScanner.onDeviceSpotted.stream.listen(onBleDeviceSpotted);

        // Events vom BleAdvertiser und BleScanner zum ViewModel weiterleiten
        _bleAdvertiser.onAdvertisingStatusChanged.stream.listen((status) {
            onBleAdvertiserStatusChanged.add(status);
        });
        _bleScanner.onScanningStatusChanged.stream.listen((status) {
            onBleScannerStatusChanged.add(status);
        });
    }

    /// Wird aufgerufen, wenn ein Gerät über NSD gefunden wurde.
    Future<void> _onNsdDeviceSpotted(NsdDeviceSpottedEventArgs args) async
    {
        // Wenn wir uns selbst gefunden haben, dann abbrechen.
        // Diest kann bei NSD vorkommen, wenn wir uns selbst als Gerät bewerben.
        if (args.nearbyUuid == Runtime.nearbyUuid)
        {
            return;
        }

        // Wenn wir das Gerät bereits kennen, abbrechen
        if (await NearbyDevicesContainer.containsUuid(args.nearbyUuid))
        {
            return;
        }

        // Ansonsten Gerätetaten austauschen
        await _localNetworkGateway.exchangeDeviceData(args);
    }

    /// Wird aufgerufen, wenn ein Gerät über das lokale Netzwerk aufgelöst wurde.
    Future<void> _onNetworkDeviceResolved(Device device) async
    {
        await NearbyDevicesContainer.addIfNotContains(device);
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
        await _supabaseDeviceGateway.sendDeviceDataRequest(nearbyUuid);
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
        await _supabaseDeviceGateway.sendDeviceData(nearbyUuid);

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

    /// Startet das Lauschen auf NSD-Geräte.
    Future<void> startNsdServices() async
    {
        try
        {
            await _nsdScanner.start();
            print("NSD-Scanner gestartet.");
        }
        catch (e)
        {
            print("NSD-Scanner konnte nicht gestartet werden: $e");
        }

        try
        {
            if (_localNetworkPort == -1)
            {
                print("Lokaler Netzwerk-Gateway-Port ist nicht gesetzt. NSD-Advertiser kann nicht gestartet werden.");
                return;
            }

            await _nsdAdvertiser.start(_localNetworkPort);
            print("NSD-Advertiser gestartet.");
        }
        catch (e)
        {
            print("NSD-Advertiser konnte nicht gestartet werden: $e");
        }
    }

    /// Stoppt das Lauschen auf NSD-Geräte.
    Future<void> stopNsdServices() async
    {
        try
        {
            await _nsdScanner.stop();
            print("NSD-Scanner gestoppt.");
        }
        catch (e)
        {
            print("NSD-Scanner konnte nicht gestoppt werden: $e");
        }

        try
        {
            await _nsdAdvertiser.stop();
            print("NSD-Advertiser gestoppt.");
        }
        catch (e)
        {
            print("NSD-Advertiser konnte nicht gestoppt werden: $e");
        }
    }

    /// Startet das Lauschen auf Gerätedaten im lokalen Netzwerk und unserem Supabase-Channel.
    Future<void> startListeningForDeviceData() async
    {
        try
        {
            _supabaseDeviceGateway.startListeningForDeviceData();
        }
        catch (e)
        {
            print("Fehler beim Starten des Lauschens auf Gerätedaten im Supabase-Channel: $e");
        }

        try
        {
            _localNetworkPort = await _localNetworkGateway.startListening();
        }
        catch (e)
        {
            print("Fehler beim Starten des Lauschens auf Gerätedaten im lokalen Netzwerk: $e");
        }
    }
}