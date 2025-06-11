import 'dart:io';
import 'package:flutter/material.dart';
import 'package:near_drop/onboarding/presentation/OnboardingViewModel.dart';
import 'package:near_drop/tools/PermissionHelper.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';
import 'package:provider/provider.dart';
import '../../Routes.dart';
import '../../../l10n/gen/app_localizations.dart';

class OnboardingPage extends StatelessWidget
{
    final pageViewController = PageController(
        initialPage: 0,
        keepPage: true,
    );

    @override
  Widget build(BuildContext context) {
        return ChangeNotifierProvider(
            create: (context) => OnboardingViewModel(),
            builder: (context, child) => Scaffold(
                appBar: AppBar(
                    title: Text(
                        AppLocalizations.of(context)!.onboarding_title),
                    centerTitle: true,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                ),
                body: PageView(
                    controller: pageViewController,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                        _buildNearbyDevicesPermissionArea(context),
                        _buildIOSLocalNetworkPermissionArea(context)
                    ],
                ).safeArea(),
            )
        );
  }

  Widget _buildNearbyDevicesPermissionArea(BuildContext context) {
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                Spacer(),
                Material(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(60),
                    child: Icon(
                        Platform.isAndroid ? Icons.nearby_error_rounded : Icons.bluetooth_connected_rounded,
                        size: 60,
                    ),
                ).sized(width: 120, height: 120).align(Alignment.center),
                SizedBox(height: 32),
                Text(
                    Platform.isAndroid ? AppLocalizations.of(context)!.nearby_permission_title : AppLocalizations.of(context)!.bluetooth_devices_permission_title,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                    )
                ).align(Alignment.center),
                SizedBox(height: 12),
                Text(
                    Platform.isAndroid ? AppLocalizations.of(context)!.nearby_permission_content : AppLocalizations.of(context)!.bluetooth_devices_permission_content,
                    textAlign: TextAlign.center,
                ).opacity(0.7),
                Spacer(),
                FilledButton(
                    onPressed: () async {
                        await PermissionHelper.requestNearbyPermission();

                        if (Platform.isIOS) {
                            pageViewController.animateToPage(1, duration: Duration(milliseconds: 800), curve: Curves.fastEaseInToSlowEaseOut);
                        } else {
                            Navigator.of(context).pushNamedAndRemoveUntil(Routes.nearby, (route) => false);
                        }
                    },
                    child: Text(AppLocalizations.of(context)!.grant_permission_button),
                ).sized(height: 60),
                SizedBox(height: 8),
                TextButton(onPressed: () {
                    if (Platform.isIOS) {
                        pageViewController.animateToPage(1, duration: Duration(milliseconds: 800), curve: Curves.fastEaseInToSlowEaseOut);
                    } else {
                        Navigator.of(context).pushNamedAndRemoveUntil(Routes.nearby, (route) => false);
                    }
                }, child: Text(AppLocalizations.of(context)!.grant_permission_skip_button))
            ],
        ).paddingAll(16);
  }

    Widget _buildIOSLocalNetworkPermissionArea(BuildContext context) {
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                Spacer(),
                Material(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(60),
                    child: Icon(
                        Icons.wifi_rounded,
                        size: 60,
                    ),
                ).sized(width: 120, height: 120).align(Alignment.center),
                SizedBox(height: 32),
                Text(
                    AppLocalizations.of(context)!.ios_local_network_permission_title,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                    )
                ).align(Alignment.center),
                SizedBox(height: 12),
                Text(
                    AppLocalizations.of(context)!.ios_local_network_permission_content,
                    textAlign: TextAlign.center,
                ).opacity(0.7),
                Spacer(),
                FilledButton(
                    onPressed: () async {
                        await PermissionHelper.requestIOSLocalNetworkPermission();
                        Navigator.of(context).pushNamedAndRemoveUntil(Routes.nearby, (route) => false);
                    },
                    child: Text(AppLocalizations.of(context)!.grant_permission_button),
                ).sized(height: 60),
                SizedBox(height: 8),
                TextButton(onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(Routes.nearby, (route) => false);
                }, child: Text(AppLocalizations.of(context)!.grant_permission_skip_button))
            ],
        ).paddingAll(16);
    }
}