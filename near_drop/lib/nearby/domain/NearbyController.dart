import 'dart:async';
import 'package:near_drop/nearby/data/LocalNetworkGateway.dart';
import 'package:near_drop/nearby/data/SupabaseDeviceGateway.dart';
import 'package:near_drop/nearby/data/event_args/NsdDeviceSpottedEventArgs.dart';
import 'package:near_drop/nearby/data/scan/ble/BleAdvertiser.dart';
import 'package:near_drop/nearby/data/scan/ble/BleScanner.dart';
import 'package:near_drop/nearby/data/scan/nsd/NsdAdvertiser.dart';
import 'package:near_drop/nearby/data/scan/nsd/NsdScanner.dart';
import 'package:near_drop/nearby/domain/Exchange.dart';
import 'package:near_drop/nearby/domain/NearbyDevicesContainer.dart';
import '../../Runtime.dart';
import '../../core/domain/entity/Device.dart';
import '../../main.dart';

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

    final Map<String, Exchange> _exchanges = {};
    int _localNetworkPort = -1;

    NearbyController(this._bleScanner, this._bleAdvertiser, this._nsdScanner, this._nsdAdvertiser, this._supabaseDeviceGateway, this._localNetworkGateway)
    {
        // Warten auf Ereignisse über Supabase
        _supabaseDeviceGateway.onDeviceDataReceived.stream.listen(onDeviceDataReceived);
        _supabaseDeviceGateway.onAcknowledgementReceived.stream.listen(onAcknowledgementReceived);

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

    /// Wird aufgerufen, wenn ein BLE-Gerät entdeckt wird.
    Future<void> onBleDeviceSpotted(String nearbyUuid) async
    {
        // Wenn wir das Gerät bereits kennen oder unsere Gerätedaten vor Kurzem erst gesendet haben, dann abbrechen
        if (await NearbyDevicesContainer.containsUuid(nearbyUuid) || _hasDeviceDataSent(nearbyUuid))
        {
            return;
        }

        // Ansonten senden wir unsere Gerätedaten an das gefundene Gerät
        await sendDeviceData(nearbyUuid, false);
    }

    /// Prüft, ob unsere Gerätedaten vor Kurzem an das Gerät gesendet wurden.
    bool _hasDeviceDataSent(String nearbyUuid)
    {
        Exchange? exchange = _exchanges[nearbyUuid];
        if (exchange != null && !exchange.isSendExpired)
        {
            return true;
        }

        return false;
    }

    /// Sendet unsere Gerätedaten an ein Gerät mit der gegebenen UUID.
    Future<void> sendDeviceData(String nearbyUuid, bool attachAck) async
    {
        Exchange exchange = _exchanges.putIfAbsent(nearbyUuid, () => Exchange());
        bool sent = await _supabaseDeviceGateway.sendDeviceData(nearbyUuid, attachAck);

        if (sent)
        {
            exchange.deviceDataSent = true;
            exchange.sentAt = DateTime.now(); // Zeitpunkt aktualisieren
            dprint("NearbyController: Gerätedaten an $nearbyUuid gesendet.");
        }
    }

    /// Wird aufgerufen, wenn Gerätedaten empfangen wurden.
    Future<void> onDeviceDataReceived(Device device) async
    {
        Exchange exchange = _exchanges.putIfAbsent(device.nearbyUuid, () => Exchange());
        exchange.receivedDevice = device;

        // Prüfen, ob wir unsere Gerätedaten bereits gesendet haben
        if (exchange.deviceDataSent)
        {
            // Nur ACK senden, um zu bestätigen, dass die Gerätedaten empfangen wurden.
            await _supabaseDeviceGateway.sendAcknowledgement(device.nearbyUuid);
            dprint("NearbyController: Gerätedaten von ${device.nearbyUuid} empfangen und ACK gesendet.");
        }
        else
        {
            // Ansonsten senden wir unsere Gerätedaten zurück und senden ein ACK mit, um eine Nachricht zu sparen
            await sendDeviceData(device.nearbyUuid, true);
            dprint("NearbyController: Gerätedaten von ${device.nearbyUuid} empfangen. Unsere Gerätedaten und ACK gesendet.");
        }

        // Wenn der Austausch abgeschlossen ist, dann Gerät hinzufügen
        if (exchange.isFinished)
        {
            await NearbyDevicesContainer.addIfNotContains(device);
            _exchanges.remove(device.nearbyUuid);
            dprint("NearbyController: Austausch mit ${device.nearbyUuid} abgeschlossen. Gerät hinzugefügt.");
        }
    }

    /// Wird aufgerufen, wenn eine Bestätigung (ACK) von einem Gerät empfangen wurde.
    Future<void> onAcknowledgementReceived(String nearbyUuid) async
    {
        // Wenn kein Austausch mit diesem Gerät existiert, dann abbrechen.
        Exchange? exchange = _exchanges[nearbyUuid];
        if (exchange == null)
        {
            return;
        }

        exchange.acknowledgeReceived = true;
        dprint("NearbyController: ACK von $nearbyUuid empfangen.");

        // Wenn der Austausch abgeschlossen ist, dann Gerät hinzufügen
        if (exchange.isFinished)
        {
            await NearbyDevicesContainer.addIfNotContains(exchange.receivedDevice!);
            _exchanges.remove(nearbyUuid);
            dprint("NearbyController: Austausch mit $nearbyUuid abgeschlossen. Gerät hinzugefügt.");
        }
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
        dprint("NearbyController: NSD-Gerät gefunden: ${args.nearbyUuid}. Tausche Gerätedaten aus.)");
        _exchanges.putIfAbsent(args.nearbyUuid, () => Exchange()); // Exchange anlegen, um zu verhindern, dass zeitgleich der Austausch über Supabase gestartet wird
        await _localNetworkGateway.exchangeDeviceData(args);
    }

    /// Wird aufgerufen, wenn ein Gerät über das lokale Netzwerk aufgelöst wurde.
    Future<void> _onNetworkDeviceResolved(Device device) async
    {
        await NearbyDevicesContainer.addIfNotContains(device);
        _exchanges.remove(device.nearbyUuid);
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
            dprint("BLE-Scanner konnte nicht gestartet werden: $e");
        }

        try
        {
            await _bleAdvertiser.start();
        }
        catch (e)
        {
            dprint("BLE-Advertiser konnte nicht gestartet werden: $e");
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
            dprint("BLE-Scanner konnte nicht gestoppt werden: $e");
        }

        try
        {
            await _bleAdvertiser.stop();
        }
        catch (e)
        {
            dprint("BLE-Advertiser konnte nicht gestoppt werden: $e");
        }
    }

    /// Startet das Lauschen auf NSD-Geräte.
    Future<void> startNsdServices() async
    {
        try
        {
            await _nsdScanner.start();
            dprint("NSD-Scanner gestartet.");
        }
        catch (e)
        {
            dprint("NSD-Scanner konnte nicht gestartet werden: $e");
        }

        try
        {
            if (_localNetworkPort == -1)
            {
                dprint("Lokaler Netzwerk-Gateway-Port ist nicht gesetzt. NSD-Advertiser kann nicht gestartet werden.");
                return;
            }

            await _nsdAdvertiser.start(_localNetworkPort);
            dprint("NSD-Advertiser gestartet.");
        }
        catch (e)
        {
            dprint("NSD-Advertiser konnte nicht gestartet werden: $e");
        }
    }

    /// Stoppt das Lauschen auf NSD-Geräte.
    Future<void> stopNsdServices() async
    {
        try
        {
            await _nsdScanner.stop();
            dprint("NSD-Scanner gestoppt.");
        }
        catch (e)
        {
            dprint("NSD-Scanner konnte nicht gestoppt werden: $e");
        }

        try
        {
            await _nsdAdvertiser.stop();
            dprint("NSD-Advertiser gestoppt.");
        }
        catch (e)
        {
            dprint("NSD-Advertiser konnte nicht gestoppt werden: $e");
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
            dprint("Fehler beim Starten des Lauschens auf Gerätedaten im Supabase-Channel: $e");
        }

        try
        {
            _localNetworkPort = await _localNetworkGateway.startListening();
        }
        catch (e)
        {
            dprint("Fehler beim Starten des Lauschens auf Gerätedaten im lokalen Netzwerk: $e");
        }
    }
}