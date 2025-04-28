import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/nearby/domain/NearbyController.dart';
import 'package:near_drop/nearby/domain/NearbyDevicesContainer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/entity/Device.dart';

/// Interaktionslogik der NearbyPage.
class NearbyViewModel extends ChangeNotifier
{
    final NearbyController _nearbyController = KiwiContainer().resolve<NearbyController>();

    final List<Device> nearbyDevices = [];
    bool isBluetoothSupported = true;
    bool isBluetoothEnabled = true;
    bool hasBluetoothPermissions = true;

    NearbyViewModel()
    {
        NearbyDevicesContainer.onAdded.stream.listen((device) {
            nearbyDevices.add(device);
            notifyListeners();
        });

        NearbyDevicesContainer.onRemoved.stream.listen((device) {
            nearbyDevices.remove(device);
            notifyListeners();
        });

        _checkBluetoothSupport();
        if (isBluetoothSupported)
        {
            _listenForBluetoothStateChanged();
        }

        _nearbyController.startListeningForDeviceData();
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
            if (await Permission.bluetoothScan.isGranted && await Permission.bluetoothAdvertise.isGranted && await Permission.bluetoothConnect.isGranted)
            {
                return true;
            }

            Map<Permission, PermissionStatus> statuses = await [
                Permission.bluetoothScan,
                Permission.bluetoothAdvertise,
                Permission.bluetoothConnect
            ].request();

            if (statuses[Permission.bluetoothScan] == PermissionStatus.granted && statuses[Permission.bluetoothAdvertise] == PermissionStatus.granted && statuses[Permission.bluetoothConnect] == PermissionStatus.granted)
            {
                return true;
            }

            return false;
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
}