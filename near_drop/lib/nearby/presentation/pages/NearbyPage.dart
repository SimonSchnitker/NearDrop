import 'dart:io';
import 'dart:math';

import 'package:balloon_widget/balloon_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:near_drop/core/entity/CommunicationInfo.dart';
import 'package:near_drop/core/enums/DeviceType.dart';
import 'package:near_drop/core/enums/SuccessState.dart';
import 'package:near_drop/nearby/presentation/viewmodel/NearbyViewModel.dart';
import 'package:near_drop/nearby/presentation/widgets/ManuallyConnectingBottomSheet.dart';
import 'package:near_drop/tools/ui/FlexibleAppBar.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';
import 'package:near_drop/transport/presentation/TransportViewModel.dart';
import 'package:provider/provider.dart';
import '../../../Runtime.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/entity/Device.dart';
import '../../../core/enums/CommunicationState.dart';
import '../../../core/enums/ErrorState.dart';
import '../../../core/enums/OS.dart';

class NearbyPage extends StatelessWidget
{
    // Key, um Dialoge von überall anzuzeigen
    static final GlobalKey<NavigatorState> scaffoldKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
      final transportViewModel = TransportViewModel();
      transportViewModel.initSignaling();

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
          key: scaffoldKey,
        drawer: _drawerAppInfo(context),
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
                    child: SizedBox()
                  ),
                )
              ],
            ),
            Column(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                    //_infoBar(context, "Bluetooth deaktiviert", "Aktiviere Bluetooth, um Geräte in der Nähe zu finden", Icons.bluetooth_disabled),
                    _infoBar(
                        context,
                        AppLocalizations.of(context)!.no_internet_connection_info_bar_title,
                        AppLocalizations.of(context)!.no_internet_connection_info_bar_subtitle,
                        Icons.wifi_off_outlined
                    ).visible(!context.watch<NearbyViewModel>().isConnectedWithNetwork),
                    _infoBar(
                        context,
                        "Bluetooth-Probleme",
                        "Einige Bluetooth-Prozesse konnten nicht gestartet werden. Schaue in der Hilfe nach für Problemlösungen.",
                        Icons.bluetooth_disabled
                    ).visible(!context.watch<NearbyViewModel>().isBleAdvertiserRunning || !context.watch<NearbyViewModel>().isBleScannerRunning),
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

  Widget _drawerAppInfo(BuildContext context) {
      return Drawer(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                        AppLocalizations.of(context)!.app_info_title,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w500)
                    ),
                    Spacer(),
                    IconButton(
                        onPressed: () {
                            Navigator.of(context).pop();
                        },
                        icon: Icon(Icons.close),
                        tooltip: AppLocalizations.of(context)!.drawer_close,
                    )
                  ],
                ),
                SizedBox(height: 16),
                Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                        children: [
                            ListTile(

                                title: Text(AppLocalizations.of(context)!.imprint_title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface),),
                                leading: Icon(Icons.info_outline),
                                iconColor: Theme.of(context).colorScheme.onSurface,
                                onTap: () {

                                },
                            ),
                            ListTile(
                                title: Text(AppLocalizations.of(context)!.data_privacy_title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                leading: Icon(Icons.shield_outlined),
                                iconColor: Theme.of(context).colorScheme.onSurface,
                                onTap: () {

                                },
                            ),
                            ListTile(
                                title: Text(AppLocalizations.of(context)!.licenses_title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                leading: Icon(Icons.verified_user_outlined),
                                iconColor: Theme.of(context).colorScheme.onSurface,
                                onTap: () {
                                    showLicensePage(context: context);
                                },
                            )
                        ],
                    ),
                ),
                Spacer(),
                Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    child: ListTile(
                        title: Text(AppLocalizations.of(context)!.version_title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                        subtitle: Text(Runtime.getVersionString()),
                        iconColor: Theme.of(context).colorScheme.onSurface,
                        leading: Icon(Icons.install_mobile_outlined),
                    ),
                )
            ],
        )
            .safeArea()
            .paddingOnly(left: 16, right: 16, bottom: 16),
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

  /// Gibt je nach Gerätetyp ein passendes Icon zurück.
  IconData _getDeviceIcon(DeviceType type) {
      switch (type) {
          case DeviceType.phone:
              return Icons.phone_iphone_outlined;
          case DeviceType.tablet:
              return Icons.tablet_mac_outlined;
          case DeviceType.laptop:
              return Icons.laptop_mac_outlined;
          case DeviceType.pc:
              return Icons.monitor;
          default:
              return Icons.device_unknown_outlined;
      }
  }

  Widget _deviceItem(BuildContext context, Device device) {
    return ChangeNotifierProvider(
        create: (context) => device,
        builder: (context, child) => Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(44),
        child: ChangeNotifierProvider(
            create: (context) => device.communicationInfo,
            builder: (context, child) => Row(
              spacing: 12,
              children: [
                Stack(
                    alignment: Alignment.center,
                    children: [
                        CircleAvatar(
                            radius: 32,
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            child: Icon(
                                _getDeviceIcon(device.type),
                                size: 28,
                            ),
                        ),
                        SizedBox(
                            width: 58,
                            height: 58,
                            child: context.watch<CommunicationInfo>().progress == null ?
                            CircularProgressIndicator(
                                value: null,
                                strokeWidth: 6,
                                strokeCap: StrokeCap.round,
                            ) :
                            TweenAnimationBuilder(
                                tween: Tween<double>(end: context.watch<CommunicationInfo>().progress == null ? 0.0 : context.watch<CommunicationInfo>().progress!),
                                duration: Duration(milliseconds: 400),
                                curve: Curves.linearToEaseOut,
                                builder: (context, double value, child) => CircularProgressIndicator(
                                    value: value,
                                    strokeCap: StrokeCap.round,
                                    strokeWidth: 6,
                                ),
                            ),
                        ),
                        Builder(builder: (context) {
                            if (context.watch<CommunicationInfo>().successState != SuccessState.none) {
                                return CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    radius: 32,
                                    child: Icon(
                                        Icons.check,
                                        size: 28,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                );
                            }
                            else if (context.watch<CommunicationInfo>().errorState != ErrorState.none) {
                                return CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                    radius: 32,
                                    child: Icon(
                                        Icons.error_outline,
                                        size: 28,
                                        color: Theme.of(context).colorScheme.onError,
                                    ),
                                );
                            }
                            return SizedBox();
                        },
                        ),
                    ],
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
                          Builder(builder: (context) {
                              CommunicationInfo info = context.watch<CommunicationInfo>();
                              if (info.communicationState == CommunicationState.none && info.successState == SuccessState.none && info.errorState == ErrorState.none) {
                                  return Text(
                                      device.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 12,
                                      ),
                                  ).opacity(0.5);
                              }
                              return Text(
                                  _getCommunicationInfoText(context, info),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: info.errorState != ErrorState.none ?
                                      Theme.of(context).colorScheme.error :
                                      Theme.of(context).colorScheme.primary,
                                  ),
                              );
                          }
                          )
                      ],
                  ).expanded()
              ],
            )
        )
        .paddingSymmetric(horizontal: 12)
        .clickable(
          borderRadius: BorderRadius.circular(44),
          onTap: () async {
              if (device.communicationInfo.communicationState == CommunicationState.none) {
                  if (!context.read<NearbyViewModel>().isConnectedWithNetwork) {
                      return;
                  }

                  // Auf Desktops wird sofort der File-Picker geöffnet
                  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
                      if (result != null) {
                          List<File> files = result.paths.map((path) => File(path!)).toList();
                          await _handleSendFiles(context, device, files);
                      }
                  } else {
                      showDialog(context: context, builder: (dialogContext) => _sendDialog(context, device));
                  }
              }
              else if (device.communicationInfo.communicationState != CommunicationState.canceling) {
                  device.isCancelTransportDialogOpen = true;
                  await showDialog(context: context, builder: (dialogContext) => _cancelTransportDialog(context, device));
                  device.isCancelTransportDialogOpen = false;
              }
          }
    ),
      )
    );
  }

  String _getCommunicationInfoText(BuildContext context, CommunicationInfo info) {
      switch (info.communicationState) {
          case CommunicationState.connecting:
              return AppLocalizations.of(context)!.communication_state_connecting;
          case CommunicationState.requesting:
              return AppLocalizations.of(context)!.communication_state_requesting;
          case CommunicationState.sending:
              return AppLocalizations.of(context)!.communication_state_sending;
          case CommunicationState.receiving:
              return AppLocalizations.of(context)!.communication_state_receiving;
            case CommunicationState.canceling:
                return AppLocalizations.of(context)!.communication_state_canceling;
          default:
              break;
      }

      switch (info.successState) {
            case SuccessState.sendedSuccessfully:
                return AppLocalizations.of(context)!.success_state_sended;
            case SuccessState.receivedSuccessfully:
                return AppLocalizations.of(context)!.success_state_received;
            default:
                break;
      }

        switch (info.errorState) {
            case ErrorState.error:
                return AppLocalizations.of(context)!.error_state_error;
            case ErrorState.receiverDeclined:
                return AppLocalizations.of(context)!.error_state_receiver_declined;
            case ErrorState.userCanceled:
                return AppLocalizations.of(context)!.error_state_canceled;
            default:
                break;
        }

      return "";
  }

  Widget _appBar(BuildContext context) {
    return FlexibleAppBar(
      title: AppLocalizations.of(context)!.app_name,
      leading: Builder(builder: (context) {
        return IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        );
      }),
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
                showModalBottomSheet(
                    context: context,
                    builder: (context) => manuallyConnectingView(context),
                    isScrollControlled: true,
                    showDragHandle: true,
                    sheetAnimationStyle: AnimationStyle(
                        duration: Duration(milliseconds: 380),
                        reverseDuration: Duration(milliseconds: 250),
                    ),
                );
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

  Widget _cancelTransportDialog(BuildContext context, Device device) {
      return AlertDialog(
        key: device.cancelTransportDialogKey,
        shadowColor: Theme.of(context).colorScheme.shadow,
        actionsPadding: EdgeInsets.only(bottom: 16, right: 24, left: 24),
        title: Text(
            "Übertragung mit ${device.firstname} beenden?",
        ),
        actions: [
            TextButton(
                onPressed: () {
                    Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.cancel_button,)
            ),
            TextButton(
                onPressed: () {
                    Navigator.of(context).pop();
                    context.read<TransportViewModel>().cancelTransport(device);
                },
                child: Text("Beenden")
            )
        ],
      );
  }

  Widget _sendDialog(BuildContext context, Device device) {
      return AlertDialog(shadowColor: Theme.of(context).colorScheme.shadow,
          actionsPadding: EdgeInsets.only(bottom: 16, right: 24),
          title: Text(
              AppLocalizations.of(context)!.send_dialog_title(device.firstname),
          ),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Material(
                    clipBehavior: Clip.hardEdge,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16), bottom: Radius.circular(4)),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: ListTile(
                        leading: Icon(Icons.insert_photo_outlined, color: Theme.of(context).colorScheme.onPrimaryContainer,),
                        title: Text(
                            AppLocalizations.of(context)!.send_dialog_media_label,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                        ),
                        onTap: () async {
                            final List<XFile> medias = await ImagePicker().pickMultipleMedia();
                            if (medias.isNotEmpty) {
                                Navigator.of(context).pop();
                                List<File> files = medias.map((e) => File(e.path)).toList();
                                await _handleSendFiles(context, device, files);
                            }
                        },
                    ),
                ),
                  Material(
                      clipBehavior: Clip.hardEdge,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4), bottom: Radius.circular(16)),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: ListTile(
                          leading: Icon(Icons.file_copy_outlined, color: Theme.of(context).colorScheme.onPrimaryContainer,),
                          title: Text(
                              AppLocalizations.of(context)!.send_dialog_files_label,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                          ),
                          onTap: () async {
                              FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
                              if (result != null) {
                                  Navigator.of(context).pop();
                                  List<File> files = result.paths.map((path) => File(path!)).toList();
                                  await _handleSendFiles(context, device, files);
                              }
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
                    AppLocalizations.of(context)!.cancel_button,
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
