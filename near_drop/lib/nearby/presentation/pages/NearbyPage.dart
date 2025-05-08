import 'dart:io';
import 'dart:math';

import 'package:balloon_widget/balloon_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:near_drop/core/entity/CommunicationInfo.dart';
import 'package:near_drop/core/enums/DeviceType.dart';
import 'package:near_drop/nearby/presentation/viewmodel/NearbyViewModel.dart';
import 'package:near_drop/tools/ui/FlexibleAppBar.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';
import 'package:near_drop/transport/presentation/TransportViewModel.dart';
import 'package:provider/provider.dart';
import '../../../Runtime.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/entity/Device.dart';
import '../../../core/enums/OS.dart';

class NearbyPage extends StatelessWidget
{
  @override
  Widget build(BuildContext context) {
      final transportViewModel = TransportViewModel();
      transportViewModel.init();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NearbyViewModel>(
          create: (context) => NearbyViewModel(),
        ),
        ChangeNotifierProvider<TransportViewModel>(
            create: (context) => transportViewModel
        )
      ],
      builder: (context, child) => Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              physics: PageScrollPhysics(),
              slivers: [
                _appBar(context),
                SliverToBoxAdapter(
                  child: Text(
                      AppLocalizations.of(context)!.nearby_page_devices_label,
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
                    child: SizedBox(
                        child: Column(
                            children: [
                                FilledButton(onPressed: () {
                                    context.read<NearbyViewModel>().toggleDeviceNotFoundBalloonVisible();
                                }, child: Text("Balloon widget")),
                                FilledButton(onPressed: () {
                                    context.read<NearbyViewModel>().startBleScan();
                                }, child: Text("BLE scan")),
                                FilledButton(onPressed: () {
                                    context.read<NearbyViewModel>().startBleAdvertiser();
                                }, child: Text("BLE advertise")),
                                FilledButton(onPressed: () {
                                    context.read<NearbyViewModel>().stopBleScan();
                                }, child: Text("Stop BLE scan")),
                                FilledButton(onPressed: () {
                                    context.read<NearbyViewModel>().stopBleAdvertiser();
                                }, child: Text("Stop BLE advertise")),
                            ],
                        ),
                    )
                  ),
                )
              ],
            ),
            Column(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                    //_infoBar(context, "Bluetooth deaktiviert", "Aktiviere Bluetooth, um Geräte in der Nähe zu finden", Icons.bluetooth_disabled),
                    _bottomBar(context)
                ],
            )
            .safeArea()
            .paddingAll(16)
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
            ChangeNotifierProvider(
                create: (context) => device.communicationInfo,
                builder: (context, child) => Stack(
                    alignment: Alignment.center,
                    children: [
                        CircleAvatar(
                            radius: 32,
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            child: Icon(
                                Icons.phone_iphone_outlined,
                                size: 28,
                            ),
                        ),
                        CircularProgressIndicator(
                            value: context.watch<CommunicationInfo>().progress,
                            strokeCap: StrokeCap.round,
                            strokeWidth: 6,
                        ).sized(height: 58, width: 58)
                    ],
                )
            ),
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.watch<Device>().firstname,
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
            showDialog(
                context: context,
                builder: (dialogContext) => _sendDialog(context, device)
            );
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

          }, icon: Icon(Icons.help_outline)),
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
      PositionedBalloon.fade(
          duration: Duration(milliseconds: 300),
          show: context.watch<NearbyViewModel>().isDeviceNotFoundBalloonVisible,
          balloon: Balloon(
              color: Theme.of(context).colorScheme.inverseSurface,
              child: Container(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        AppLocalizations.of(context)!.nearby_page_no_devices_found_balloon_title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onInverseSurface,
                        ),
                    ),
                      Text(
                          AppLocalizations.of(context)!.nearby_page_no_devices_found_balloon_subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onInverseSurface,
                            ),
                      )
                  ],
                ).paddingSymmetric(horizontal: 8, vertical: 4),
              )
              .onTap(() {
                  context.read<NearbyViewModel>().toggleDeviceNotFoundBalloonVisible();
              })
          ),
        child: Material(
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
      )
    ]);
  }

  Widget _infoBar(BuildContext context, String title, String subtitle, IconData icon) {
      return Material(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
          child: Row(
              spacing: 12,
              children: [
                  Icon(
                      icon,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(
                              title,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onErrorContainer),
                          ),
                          Text(
                              subtitle,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                          )
                      ],
                  )
                  .expanded()
              ],
          )
          .paddingAll(16)
      );
  }

  Widget _sendDialog(BuildContext context, Device device) {
      return AlertDialog(shadowColor: Theme.of(context).colorScheme.shadow,
          actionsPadding: EdgeInsets.only(bottom: 16, right: 24),
          title: Text(
              "An ${device.firstname} senden",
          ),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Material(
                    clipBehavior: Clip.hardEdge,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16), bottom: Radius.circular(4)),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: ListTile(
                        leading: Icon(Icons.insert_photo_outlined),
                        title: Text("Fotos & Videos"),
                        onTap: () async {
                            final List<XFile> medias = await ImagePicker().pickMultipleMedia();
                            if (medias.isNotEmpty) {
                                List<File> files = medias.map((e) => File(e.path)).toList();
                                await _handleSendFiles(context, device, files);
                            }
                        },
                    ),
                ),
                  Material(
                      clipBehavior: Clip.hardEdge,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4), bottom: Radius.circular(16)),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: ListTile(
                          leading: Icon(Icons.file_copy_outlined),
                          title: Text("Dateien"),
                          onTap: () {

                          },
                      ),
                  )
              ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                    Navigator.of(context).pop();
                },
                child: Text(
                    "Abbrechen",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary
                    ),
                )
            )
          ],
      );
  }

  Future<void> _handleSendFiles(BuildContext context, Device device, List<File> files) async {
     await context.read<TransportViewModel>().sendFiles(device, files);
  }
}
