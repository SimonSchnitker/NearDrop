import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/auth/domain/AuthController.dart';
import 'package:near_drop/core/domain/CoreController.dart';
import 'package:near_drop/nearby/domain/NearbyController.dart';
import 'package:near_drop/nearby/domain/NearbyDevicesContainer.dart';
import 'package:near_drop/transport/domain/TransportController.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../Runtime.dart';
import '../../../core/domain/entity/Device.dart';

/// Interaktionslogik der NearbyPage.
class NearbyViewModel extends ChangeNotifier
{
    final NearbyController _nearbyController = KiwiContainer().resolve<NearbyController>();
    final TransportController _transportController = KiwiContainer().resolve<TransportController>();
    final CoreController _coreController = KiwiContainer().resolve<CoreController>();

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
    bool isBleScannerRunning = true;
    bool isBleAdvertiserRunning = true;
    get isBluetoothErrorBarVisible => (!isBleAdvertiserRunning || !isBleScannerRunning) && isBluetoothEnabled && hasBluetoothPermissions;

    bool isDeviceNotFoundBalloonVisible = false;
    final Duration deviceNotFoundBalloonDelay = const Duration(seconds: 8);

    // Diese Werte werden verwendet, um die Sichtbarkeit der Info-Nachrichten zu steuern.
    bool isInfoAreaVisible = false;
    get isInfoMessagesButtonVisible => !isConnectedWithNetwork || !isBluetoothSupported || !isBluetoothEnabled || !hasBluetoothPermissions || isBluetoothErrorBarVisible;

    NearbyViewModel()
    {
        // Auf Änderungen des Vornamens lauschen
        Runtime.onFirstnameChanged.stream.listen((newFirstname) {
            firstname = newFirstname;
            notifyListeners();
        });

        // Auf Änderungen des Bluetooth-Status lauschen
        _nearbyController.onBleAdvertiserStatusChanged.stream.listen((isAdverstising) {
            isBleAdvertiserRunning = isAdverstising;
            notifyListeners();
        });
        _nearbyController.onBleScannerStatusChanged.stream.listen((isScanning) {
            isBleScannerRunning = isScanning;
            notifyListeners();
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

        _listenNetworkStateChanges();
        initializeCore();
    }

    /// Initialisiert die Core-Funktionen der App.
    Future<void> initializeCore() async
    {
        isInitializingFailed = false;
        isInitializingNearbyUuid = true;
        notifyListeners();

        try
        {
            await _coreController.inizialize();
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
        _nearbyController.startListeningForDeviceData();
        _transportController.startSignaling();
        _listenForBluetoothStateChanges();
    }

    /// Zeigt die Info-Nachrichten an oder blendet sie aus.
    void toggleInfoMessagesVisibility()
    {
        isInfoAreaVisible = !isInfoAreaVisible;
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
        Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
            if (result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.ethernet))
            {
                isConnectedWithNetwork = true;
            }
            else
            {
                isConnectedWithNetwork = false;
            }

            notifyListeners();
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

                hasBluetoothPermissions = await _requestBluetoothPermission();
                if (hasBluetoothPermissions)
                {
                    hasBluetoothPermissions = true;
                    await _nearbyController.startBleServices();
                    _showDeviceNotFoundBalloonAfterDelay();
                }
            }
            else if (state == BluetoothAdapterState.off)
            {
                isBluetoothEnabled = false;
                await _nearbyController.stopBleServices();
            }

            notifyListeners();
        });
    }

    /// Fordert die Berechtigungen für Bluetooth an.
    Future<bool> _requestBluetoothPermission() async
    {
        if (Platform.isAndroid)
        {
            final androidInfo = await DeviceInfoPlugin().androidInfo;

            if (androidInfo.version.sdkInt >= 31) // Android 12 und höher
            {
                if (await Permission.bluetoothScan.isGranted && await Permission.bluetoothAdvertise.isGranted && await Permission.bluetoothConnect.isGranted)
                {
                    return true;
                }

                Map<Permission, PermissionStatus> statuses = await [
                    Permission.bluetoothScan,
                    Permission.bluetoothAdvertise,
                    Permission.bluetoothConnect
                ].request();

                for (var status in statuses.values)
                {
                    if (status != PermissionStatus.granted)
                    {
                        return false;
                    }
                }

                return true;
            }
            else // Für Android 11 und niedriger wird für Bluetooth die Standortberechtigung benötigt
            {
                if (await Permission.location.isGranted)
                {
                    return true;
                }

                return await Permission.location.request() == PermissionStatus.granted;
            }
        }
        else if (Platform.isIOS)
        {
            if (await Permission.bluetooth.isGranted)
            {
                return true;
            }

            return await Permission.bluetooth.request() == PermissionStatus.granted;
        }
        else
        {
            return true; // Für Windows und macOS ist keine Berechtigung erforderlich
        }
    }

    /// Zeigt eine Ballon-Nachricht an, wenn nach einem Delay immer noch keine Geräte gefunden wurden.
    Future<void> _showDeviceNotFoundBalloonAfterDelay() async
    {
        await Future.delayed(deviceNotFoundBalloonDelay);

        // Wenn nach dem Delay immer noch keine Geräte gefunden wurden, die Ballon-Nachricht anzeigen.
        if (nearbyDevices.isEmpty)
        {
            isDeviceNotFoundBalloonVisible = true;
            notifyListeners();
        }
    }
}