import 'dart:io';
import 'package:flutter/material.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../Runtime.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../viewmodel/ManuallyConnectingViewModel.dart';

Widget manuallyConnectingView(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => ManuallyConnectingViewModel(),
        builder: (context, child) => SizedBox(
            width: double.infinity,
            child: AnimatedSize(
                duration: Duration(milliseconds: 500),
                curve: Curves.linearToEaseOut,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Text(
                            AppLocalizations.of(context)!.manually_connecting_sheet_title,
                            style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 24,),
                        _qrCodeConnectionView(context)
                    ],
                )
                    .safeArea()
                    .paddingOnly(left: 16, right: 16, bottom: 16),
            ),
        ),
    );
}

Widget _qrCodeConnectionView(BuildContext context) {
    switch (context.watch<ManuallyConnectingViewModel>().qrState)
    {
        case QrState.showingQr:
            return _showQrCodeView(context);
        case QrState.scanningQr:
            return _scanQrCodeView(context);
        case QrState.loading:
            return CircularProgressIndicator(
                strokeCap: StrokeCap.round,
            ).centered()
                .paddingSymmetric(vertical: 8);
    }
}

Widget _showQrCodeView(BuildContext context) {
    return Column(
        children: [
            if (context.watch<ManuallyConnectingViewModel>().scanResultError == ScanResultError.noPermission)
                Text(
                    AppLocalizations.of(context)!.qr_code_error_no_permission,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error,),
                ).paddingSymmetric(horizontal: 40),
            if (context.watch<ManuallyConnectingViewModel>().scanResultError != ScanResultError.noPermission)
                Text(
                    AppLocalizations.of(context)!.qr_code_text,
                    textAlign: TextAlign.center,
                ).paddingSymmetric(horizontal: 40),
            SizedBox(height: 24,),
            Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.inverseSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Theme.of(context).brightness == Brightness.light ? Border.all(color: Theme.of(context).colorScheme.surfaceDim, width: 1) : null,
                ),
                child: QrImageView(
                    data: Runtime.nearbyUuid,
                    //data: "https://www.youtube.com/watch?v=xvFZjo5PgG0", // Für Store-Screenshots
                    size: 210,
                    padding: EdgeInsets.all(16),
                    dataModuleStyle: QrDataModuleStyle(
                        color: Theme.of(context).brightness == Brightness.light ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onInverseSurface,
                        dataModuleShape: QrDataModuleShape.circle
                    ),
                    eyeStyle: QrEyeStyle(
                        color: Theme.of(context).brightness == Brightness.light ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onInverseSurface,
                        eyeShape: QrEyeShape.circle
                    ),
                ),
            ),
            SizedBox(height: 24,),
            FilledButton.tonal(onPressed: () {
                context.read<ManuallyConnectingViewModel>().setQrState(QrState.scanningQr);
            }, child: Text(AppLocalizations.of(context)!.manually_connecting_sheet_scan_button)
            ).visible(Platform.isAndroid || Platform.isIOS)
        ],
    );
}

Widget _scanQrCodeView(BuildContext context) {
    return Column(
        children: [
            if (context.watch<ManuallyConnectingViewModel>().scanResultError == ScanResultError.none)
                Text(
                    AppLocalizations.of(context)!.scan_qr_code,
                    textAlign: TextAlign.center,
                ).paddingSymmetric(horizontal: 40),
            if (context.watch<ManuallyConnectingViewModel>().scanResultError == ScanResultError.invalidQrCode)
                Text(
                    AppLocalizations.of(context)!.qr_code_error_invalid,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error,),
                ).paddingSymmetric(horizontal: 40),
            if (context.watch<ManuallyConnectingViewModel>().scanResultError == ScanResultError.deviceAlreadyAdded)
                Text(
                    AppLocalizations.of(context)!.qr_code_error_device_already_added,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error,),
                ).paddingSymmetric(horizontal: 40),
            SizedBox(height: 24,),
            Container(
                height: 210,
                width: 210,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                ),
                child: QRView(
                    key: context.read<ManuallyConnectingViewModel>().qrKey,
                    formatsAllowed: [BarcodeFormat.qrcode],
                    onQRViewCreated: context.read<ManuallyConnectingViewModel>().onQRViewCreated,
                    onPermissionSet: context.read<ManuallyConnectingViewModel>().onPermissionSet,
                ),
            ),
            SizedBox(height: 24,),
            FilledButton.tonal(onPressed: () {
                context.read<ManuallyConnectingViewModel>().setQrState(QrState.showingQr);
            }, child: Text(AppLocalizations.of(context)!.cancel_button)),
        ],
    );
}