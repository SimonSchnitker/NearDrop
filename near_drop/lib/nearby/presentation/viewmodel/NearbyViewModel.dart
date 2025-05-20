import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/nearby/domain/NearbyController.dart';
import 'package:near_drop/nearby/domain/NearbyDevicesContainer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/entity/Device.dart';
import '../../../core/enums/DeviceType.dart';
import '../../../core/enums/OS.dart';

/// Interaktionslogik der NearbyPage.
class NearbyViewModel extends ChangeNotifier
{
    final NearbyController _nearbyController = KiwiContainer().resolve<NearbyController>();

    final List<Device> nearbyDevices = [];
    bool isConnectedWithNetwork = true;
    bool isBluetoothSupported = true;
    bool isBluetoothEnabled = true;
    bool hasBluetoothPermissions = true;
    bool isBleScannerRunning = true;
    bool isBleAdvertiserRunning = true;

    bool isDeviceNotFoundBalloonVisible = false;
    final Duration deviceNotFoundBalloonDelay = const Duration(seconds: 8);

    NearbyViewModel()
    {
        // Testdaten
        for (int i = 0; i < 2; i++)
        {
            nearbyDevices.add(Device(
                "Simon",
                "Pixel 9 Pro",
                DeviceType.phone,
                OS.android,
                1,
                ""
            ));
        }

        // Auf Änderungen des Bluetooth-Status lauschen
        _nearbyController.onBleAdvertiserStatusChanged.stream.listen((isAdverstising) {
            isBleAdvertiserRunning = isAdverstising;
            notifyListeners();
        });
        _nearbyController.onBleScannerStatusChanged.stream.listen((isScanning) {
            isBleScannerRunning = isScanning;
            notifyListeners();
        });

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
        _checkBluetoothSupport();
        if (isBluetoothSupported)
        {
            _listenForBluetoothStateChanged();
        }

        _nearbyController.startListeningForDeviceData();
    }

    void toggleDeviceNotFoundBalloonVisible()
    {
        isDeviceNotFoundBalloonVisible = !isDeviceNotFoundBalloonVisible;
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

    /// Prüft, ob das Gerät Bluetooth unterstützt.
    Future<void> _checkBluetoothSupport() async
    {
        if (await FlutterBluePlus.isSupported == false)
        {
            isBluetoothSupported = false;
        }
    }

    /// Lauscht auf Änderungen des Bluetooth-Status.
    void _listenForBluetoothStateChanged()
    {
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

        // Wenn nach dem Delay immer noch keine Geräte gefunden wurden, zeige die Ballon-Nachricht an
        if (nearbyDevices.isEmpty)
        {
            isDeviceNotFoundBalloonVisible = true;
            notifyListeners();
        }
    }

    Future<void> startBleScan() async
    {
        await _nearbyController.startBleScanner();
    }

    Future<void> stopBleScan() async
    {
        await _nearbyController.stopBleScanner();
    }

    Future<void> startBleAdvertiser() async
    {
        await _nearbyController.startBleAdvertiser();
    }

    Future<void> stopBleAdvertiser() async
    {
        await _nearbyController.stopBleAdvertiser();
    }
}