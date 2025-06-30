import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/nearby/domain/NearbyController.dart';
import 'package:near_drop/nearby/domain/NearbyDevicesContainer.dart';
import 'package:near_drop/nearby/presentation/pages/NearbyPage.dart';
import 'package:near_drop/tools/IdHelper.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../../../main.dart';

/// Zustände die auf der UI angezeigt werden können, wenn ein QR-Code gescannt wird.
enum QrState
{
    showingQr,
    scanningQr,
    loading,
}

/// Fehler, die beim Scannen eines QR-Codes auftreten können.
enum ScanResultError
{
    none,
    deviceAlreadyAdded,
    invalidQrCode,
    noPermission,
    requestDeviceDataError,
}

/// Dieses ViewModel wird verwendet, um die Logik für das manuelle Verbinden mit einem Gerät über einen QR-Code zu verwalten.
class ManuallyConnectingViewModel extends ChangeNotifier
{
    final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
    final NearbyController _nearbyController = KiwiContainer().resolve<NearbyController>();

    QrState qrState = QrState.showingQr;
    ScanResultError scanResultError = ScanResultError.none;
    QRViewController? controller;

    /// Setzt den Zustand des QR-Codes und stoppt die Kamera, wenn der Zustand nicht `scanningQr` ist.
    void setQrState(QrState state)
    {
        if (qrState != QrState.scanningQr)
        {
            controller?.stopCamera();
        }

        qrState = state;
        notifyListeners();
    }

    void onQRViewCreated(QRViewController controller)
    {
        this.controller = controller;
        controller.scannedDataStream.listen((scanData) async
        {
            // Wenn gerade eine Fehlermeldung angezeigt wird, ignorieren
            if (scanResultError != ScanResultError.none)
            {
                return;
            }

            String data = scanData.code ?? "";
            if (data.isEmpty)
            {
                _setErrorState(ScanResultError.invalidQrCode);
                return;
            }

            if (!IdHelper.isValidDeviceUUID(data))
            {
                _setErrorState(ScanResultError.invalidQrCode);
                return;
            }

            if (await NearbyDevicesContainer.containsUuid(data))
            {
                //_setErrorState(ScanResultError.deviceAlreadyAdded);
                //return;
                // Trotzdem senden, da es sein kann (selten), dass das andere Gerät uns noch nicht kennt.
            }

            await _requestDeviceData(data);
        });
    }

    void onPermissionSet(QRViewController controller, bool permission)
    {
        if (!permission)
        {
            setQrState(QrState.showingQr);
            _setErrorState(ScanResultError.noPermission);
        }
    }

    Future<void> _setErrorState(ScanResultError error) async
    {
        scanResultError = error;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 3));
        scanResultError = ScanResultError.none;
        notifyListeners();
    }

    /// Fordert die Gerätedaten für das gegebene UUID an und schließt den ModalBottomSheet, wenn erfolgreich.
    Future<void> _requestDeviceData(String uuid) async
    {
        setQrState(QrState.loading);

        try
        {
           await _nearbyController.sendDeviceData(uuid, false);
           Navigator.of(NearbyPage.scaffoldKey.currentContext!).maybePop();
        }
        catch (e)
        {
            dprint("Fehler beim Anfordern der Gerätedaten: $e");
            _setErrorState(ScanResultError.requestDeviceDataError);
            setQrState(QrState.showingQr);
        }
    }
}