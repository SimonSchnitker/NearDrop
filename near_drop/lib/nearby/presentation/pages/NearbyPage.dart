import 'dart:io';

import 'package:flutter/material.dart';
import 'package:near_drop/core/enums/DeviceType.dart';
import 'package:near_drop/nearby/presentation/viewmodel/NearbyViewModel.dart';
import 'package:near_drop/tools/ui/FlexibleAppBar.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';
import 'package:provider/provider.dart';
import '../../../Runtime.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/entity/Device.dart';
import '../../../core/enums/OS.dart';

class NearbyPage extends StatelessWidget
{
  @override
  Widget build(BuildContext context) {
    List<Device> devices = [];

    // Testdaten
    for (int i = 0; i < 20; i++)
    {
      devices.add(Device(
        "Simon",
        "Pixel 9 Pro",
        DeviceType.phone,
        OS.android,
        1,
        ""
      ));
    }

    return ChangeNotifierProvider(
      create: (context) => NearbyViewModel(),
      builder: (context, child) => Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              physics: PageScrollPhysics(),
              slivers: [
                _appBar(context),
                SliverToBoxAdapter(
                  child: Text(
                      "Geräte in der Nähe",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ).paddingOnly(left: 16, top: 8, right: 16, bottom: 8),
                ),
                SliverPadding(
                    padding: EdgeInsets.only(left: 16, right: 16, bottom: 88),
                    sliver: _nearbyDevicesGrid(context, context.watch<NearbyViewModel>().nearbyDevices)
                ),
                SliverToBoxAdapter(
                  child: SafeArea(
                    top: false,
                    child: SizedBox()
                  ),
                )
              ],
            ),
            _bottomBar(context)
                .safeArea()
                .paddingAll(16)
                .align(Alignment.bottomCenter),
          ],
        ),
      ),
    );
  }

  Widget _nearbyDevicesGrid(BuildContext context, List<Device> devices) {
    return SliverGrid(
        delegate: SliverChildBuilderDelegate(
            childCount: devices.length,
                (context, index) {
              return _deviceItem(context, devices[index]);
            }
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 88
        )
    );
  }

  Widget _deviceItem(BuildContext context, Device device) {
    return ChangeNotifierProvider(
        create: (context) => device,
      builder: (context, child) => Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(44),
        child: Row(
          spacing: 12,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Icon(
                Icons.phone_iphone_outlined,
                size: 28,
              ),
            ),
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.firstname,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500
                  ),
                ),
                Text(
                  device.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12
                  ),
                ).opacity(0.5),
              ],
            ).expanded()
          ],
        )
        .paddingSymmetric(horizontal: 12)
        .clickable(
          borderRadius: BorderRadius.circular(44),
          onTap: () {

          }
    ),
      )
    );
  }

  Widget _appBar(BuildContext context) {
    return FlexibleAppBar(
      title: AppLocalizations.of(context)!.app_name,
      leading: IconButton(onPressed: () {

      }, icon: Icon(Icons.menu), tooltip: AppLocalizations.of(context)!.nearby_page_menu_icon_tooltip),
      actions: [
        IconButton(onPressed: () {

      }, icon: Icon(Icons.person_outline), tooltip: AppLocalizations.of(context)!.nearby_page_account_icon_tooltip)
      ],
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Row(
      spacing: 8,
        children: [
      Expanded(
        flex: (Platform.isAndroid || Platform.isIOS) ? 1 : 0,
        child: Material(
          borderRadius: BorderRadius.circular(28),
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Row(
            spacing: 12,
            children: [
              Icon(Icons.remove_red_eye_outlined),
              RichText(
                text: TextSpan(style: TextStyle(fontWeight: FontWeight.w500),
                  children: [
                    TextSpan(
                        text: AppLocalizations.of(context)!.nearby_page_visibility_info_prefix,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
                    ),
                    TextSpan(
                        text: Runtime.firstname,
                        style: TextStyle(color: Theme.of(context).colorScheme.primary)
                    ),
                    TextSpan(
                        text: ".",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
                    ),
                  ]),
              ),
            ],
          )
            .paddingSymmetric(horizontal: 16)
        )
        .sized(height: 56),
      ),
      Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        child: Icon(
            Icons.qr_code_2
        )
        .clickable(
          borderRadius: BorderRadius.circular(28),
          onTap: () {

          }
        ),
      )
      .sized(height: 56, width: 56)
      .tooltip(
        message: AppLocalizations.of(context)!.nearby_page_manual_connection_tooltip,
        preferBelow: false,
      ),
    ]);
  }
}
