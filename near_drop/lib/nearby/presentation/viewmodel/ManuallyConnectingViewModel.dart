import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/nearby/domain/NearbyController.dart';
import 'package:near_drop/nearby/domain/NearbyDevicesContainer.dart';
import 'package:near_drop/nearby/presentation/pages/NearbyPage.dart';
import 'package:near_drop/tools/IdHelper.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

enum QrState
{
    showingQr,
    scanningQr,
    loading,
}

enum ScanResultError
{
    none,
    deviceAlreadyAdded,
    invalidQrCode,
    noPermission,
    requestDeviceDataError,
}

class ManuallyConnectingViewModel extends ChangeNotifier
{
    final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
    final NearbyController _nearbyController = KiwiContainer().resolve<NearbyController>();

    QrState qrState = QrState.showingQr;
    ScanResultError scanResultError = ScanResultError.none;
    QRViewController? controller;

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
                _setErrorState(ScanResultError.deviceAlreadyAdded);
                return;
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

    Future<void> _requestDeviceData(String uuid) async
    {
        setQrState(QrState.loading);

        try
        {
           await _nearbyController.requestDeviceData(uuid);
           Navigator.of(NearbyPage.scaffoldKey.currentContext!).maybePop();
        }
        catch (e)
        {
            print("Fehler beim Anfordern der Gerätedaten: $e");
            _setErrorState(ScanResultError.requestDeviceDataError);
            setQrState(QrState.showingQr);
        }
    }
}