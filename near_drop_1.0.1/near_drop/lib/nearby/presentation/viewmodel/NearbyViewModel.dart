import 'dart:ffi';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/core/Version.dart';
import 'package:near_drop/core/domain/CoreController.dart';
import 'package:near_drop/core/domain/entity/AppVersionResponse.dart';
import 'package:near_drop/core/domain/enums/DeviceType.dart';
import 'package:near_drop/core/domain/enums/OS.dart';
import 'package:near_drop/nearby/domain/NearbyController.dart';
import 'package:near_drop/nearby/domain/NearbyDevicesContainer.dart';
import 'package:near_drop/nearby/presentation/pages/NearbyPage.dart';
import 'package:near_drop/settings/domain/SettingsController.dart';
import 'package:near_drop/tools/PermissionHelper.dart';
import 'package:near_drop/transport/domain/TransportController.dart';
import 'package:near_drop/transport/presentation/TransportViewModel.dart';
import '../../../Routes.dart';
import '../../../Runtime.dart';
import '../../../core/domain/entity/Device.dart';
import '../../../main.dart';
import '../../../settings/domain/Setting.dart';

/// Interaktionslogik der NearbyPage.
class NearbyViewModel extends ChangeNotifier
{
    final _bleRestartDuration = Duration(seconds: 5);
    final Setting _filesSentSetting = Setting("filesSent", bool);

    final NearbyController _nearbyController = KiwiContainer().resolve<NearbyController>();
    final TransportController _transportController = KiwiContainer().resolve<TransportController>();
    final CoreController _coreController = KiwiContainer().resolve<CoreController>();
    final SettingsController _settingsController = KiwiContainer().resolve<SettingsController>();

    bool isUpdateAvailable = false;
    bool isRequiredUpdateAvailable = false;

    final List<Device> nearbyDevices = [];
    String firstname = Runtime.firstname;
    bool isConnectedWithNetwork = true;
    bool isBluetoothSupported = true;
    bool isBluetoothEnabled = true;
    bool hasBluetoothPermissions = true;

    // Diese Werte geben an, ob die UUID für Nearby initialisiert wird und ob sie bereits initialisiert wurde.
    // Ohne die UUID sind die meisten Funktionen der App nicht nutzbar.
    bool isInitializingNearbyUuid = false;
    bool isNearbyUuidInitialized = false;
    bool isInitializingFailed = false;

    // Diese Werte werden verwendet, falls der BleScanner oder BleAdvertiser fehlschlagen.
    //bool isBleScannerRunning = true;
    //bool isBleAdvertiserRunning = true;
    //get isBluetoothErrorBarVisible => (!isBleAdvertiserRunning || !isBleScannerRunning) && isBluetoothEnabled && hasBluetoothPermissions;

    bool isDeviceNotFoundBalloonVisible = false;
    final Duration deviceNotFoundBalloonDelay = const Duration(seconds: 10);

    // Diese Werte werden verwendet, um die Sichtbarkeit der Info-Nachrichten zu steuern.
    bool isInfoAreaVisible = false;
    get isInfoMessagesButtonVisible => !isConnectedWithNetwork || !isBluetoothSupported || !isBluetoothEnabled || !hasBluetoothPermissions;

    NearbyViewModel()
    {
        // Für Store Screenshots
        //addTestDevices();

        // Auf Änderungen des Vornamens lauschen
        Runtime.onFirstnameChanged.stream.listen((newFirstname) {
            firstname = newFirstname;
            notifyListeners();
        });

        // Auf Änderungen des Bluetooth-Status lauschen
        _nearbyController.onBleAdvertiserStatusChanged.stream.listen((isAdverstising) {
            //isBleAdvertiserRunning = isAdverstising;
            //notifyListeners();
        });
        _nearbyController.onBleScannerStatusChanged.stream.listen((isScanning) {
            //isBleScannerRunning = isScanning;
            //notifyListeners();
        });

        // Darauf lauschen, wenn Geräte hinzugefügt oder entfernt werden.
        NearbyDevicesContainer.onAdded.stream.listen((device) {
            nearbyDevices.add(device);

            // Balloon-Nachricht wieder ausblenden, wenn ein Gerät gefunden wurde
            if (isDeviceNotFoundBalloonVisible)
            {
                isDeviceNotFoundBalloonVisible = false;
            }

            notifyListeners();
        });
        NearbyDevicesContainer.onRemoved.stream.listen((device) {
            nearbyDevices.remove(device);
            notifyListeners();
        });
        NearbyDevicesContainer.onCleared.stream.listen((_) {
            nearbyDevices.clear();
            notifyListeners();
        });

        initializeCore();
        _getVersionInfo();
    }

    void addTestDevices()
    {
        Device device1 = Device("Julian", "iPhone 16 Pro", DeviceType.phone, OS.ios, Version(1, 0, 0), "");
        //device1.communicationInfo.setSending(0.7);
        nearbyDevices.add(device1);

        Device device2 = Device("Ava", "Pixel 9 Pro", DeviceType.phone, OS.android, Version(1, 0, 0), "");
        //device2.communicationInfo.setReceiving(0.3);
        nearbyDevices.add(device2);

        nearbyDevices.add(Device("Max", "MacBook Air", DeviceType.pc, OS.macos, Version(1, 0, 0), ""));
    }

    /// Initialisiert die Core-Funktionen der App.
    Future<void> initializeCore() async
    {
        isInitializingFailed = false;
        isInitializingNearbyUuid = true;
        notifyListeners();

        try
        {
            await _coreController.initialize();
        }
        catch (e)
        {
            isInitializingNearbyUuid = false;
            isNearbyUuidInitialized = false;
            isInitializingFailed = true;
            notifyListeners();
            return;
        }

        isInitializingNearbyUuid = false;
        isNearbyUuidInitialized = true;
        isInitializingFailed = false;
        notifyListeners();

        // Wenn erfolgreich, alle notwendigen Dienste starten
        await _nearbyController.startListeningForDeviceData();
        _transportController.startSignaling();
        _listenNetworkStateChanges();

        // Wenn das Gerät eine WLAN-Verbindung hat, wird erstmal nur über NSD gesucht, um Supabase zu entlasten.
        /*
        List<ConnectivityResult> connectivity = await Connectivity().checkConnectivity();
        if (connectivity.contains(ConnectivityResult.wifi))
        {
            await Future.delayed(const Duration(milliseconds: 500));
        }
         */

        _listenForBluetoothStateChanges();
        _startBleRestartingProcess();
    }

    /// Prüft, ob eine Aktualisierung verfügbar ist und ob es sich um eine wichtige Aktualisierung handelt.
    Future<void> _getVersionInfo() async
    {
        try
        {
            AppVersionResponse response = await _coreController.getVersionInfo();
            isUpdateAvailable = response.latestVersion > Runtime.appVersion;
            isRequiredUpdateAvailable = response.requiredVersion > Runtime.appVersion;
            notifyListeners();
        }
        catch (e)
        {
            dprint("Fehler beim Abrufen der Version: $e");
            return;
        }

        // Wenn eine wichtige Aktualisierung verfügbar ist, den Nutzer informieren und alle Projekte stoppen.
        if (isRequiredUpdateAvailable)
        {
            await Navigator.of(NearbyPage.scaffoldKey.currentContext!).pushNamedAndRemoveUntil(Routes.requiredUpdate, (route) => false);
            await _nearbyController.startBleScanner();
            await _nearbyController.stopBleAdvertiser();
            await _nearbyController.startNsdServices();
            await Runtime.unsubscribeChannel();
        }
    }

    /// Zeigt die Info-Nachrichten an oder blendet sie aus.
    void toggleInfoMessagesVisibility()
    {
        isInfoAreaVisible = !isInfoAreaVisible;
        isDeviceNotFoundBalloonVisible = false; // Ballon-Nachricht ausblenden, wenn Info-Nachrichten angezeigt werden
        notifyListeners();
    }

    /// Setzt die Sichtbarkeit der Ballon-Nachricht, die angezeigt wird, wenn nach einiger Zeit kein Gerät gefunden wurde.
    void setDeviceNotFoundBalloonVisibility(bool visible)
    {
        isDeviceNotFoundBalloonVisible = visible;
        notifyListeners();
    }

    /// Startet das Lauschen auf Netzwerkstatusänderungen.
    Future<void> _listenNetworkStateChanges() async
    {
        Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) async {
            if (result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.ethernet))
            {
                isConnectedWithNetwork = true;
            }
            else
            {
                isConnectedWithNetwork = false;
            }
            notifyListeners();

            // Wenn eine WLAN-Verbindung besteht, NSD-Services starten
            if (result.contains(ConnectivityResult.wifi))
            {
                await _nearbyController.startNsdServices();
            }
            // Wenn keine WLAN-Verbindung besteht, NSD-Services stoppen
            else
            {
                await _nearbyController.stopNsdServices();
            }
        });
    }

    /// Lauscht auf Änderungen des Bluetooth-Status.
    Future<void> _listenForBluetoothStateChanges() async
    {
        if (await FlutterBluePlus.isSupported == false)
        {
            isBluetoothSupported = false;
            notifyListeners();
            return;
        }

        FlutterBluePlus.adapterState.listen((state) async {
            if (state == BluetoothAdapterState.on)
            {
                isBluetoothEnabled = true;

                hasBluetoothPermissions = await PermissionHelper.hasNearbyPermission();
                if (hasBluetoothPermissions)
                {
                    hasBluetoothPermissions = true;
                    await _nearbyController.startBleScanner();
                    await _nearbyController.startBleAdvertiser();
                    _showDeviceNotFoundBalloonAfterDelay();
                }
            }
            else if (state == BluetoothAdapterState.off)
            {
                isBluetoothEnabled = false;
                await _nearbyController.stopBleScanner();
                await _nearbyController.stopBleAdvertiser();
            }

            notifyListeners();
        });

        // Seltsamer Bug: Wenn die App längere Zeit im Hintergrund war und dann wieder geöffnet wird, scannt der BleScanner nicht mehr.
        // Daher wird der BleScanner neu gestartet, wenn die App wieder geöffnet wird.
        if (Platform.isAndroid || Platform.isIOS)
        {
            AppLifecycleListener(
                onResume: () async {
                    if (hasBluetoothPermissions && isBluetoothEnabled)
                    {
                        await _nearbyController.stopBleScanner();
                        await _nearbyController.startBleScanner();
                    }
                }
            );
        }
    }

    /// Startet regelmäßig den Bluetooth-Werbeprozess neu, weil dadurch die Sendeausstrahlung permanent hoch bleibt.
    Future<void> _startBleRestartingProcess() async
    {
        while (true)
        {
            await Future.delayed(_bleRestartDuration);
            if (isBluetoothSupported && isBluetoothEnabled && hasBluetoothPermissions)
            {
                dprint("Restarting Bluetooth advertiser...");
                await _nearbyController.stopBleAdvertiser();
                await _nearbyController.startBleAdvertiser();
            }
        }
    }

    /// Zeigt eine Ballon-Nachricht an, wenn nach einem Delay immer noch keine Geräte gefunden wurden.
    Future<void> _showDeviceNotFoundBalloonAfterDelay() async
    {
        await Future.delayed(deviceNotFoundBalloonDelay);
        bool hasFilesSent = await _settingsController.get(_filesSentSetting) ?? false;

        // Wenn nach dem Delay immer noch keine Geräte gefunden wurden,
        // keine Info-Nachrichten angezeigt werden und bereits Dateien gesendet wurden,
        // wird die Ballon-Nachricht angezeigt.
        if (nearbyDevices.isEmpty && !isInfoAreaVisible && hasFilesSent)
        {
            isDeviceNotFoundBalloonVisible = true;
            notifyListeners();
        }
    }
}