import 'dart:io';
import 'package:balloon_widget/balloon_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:near_drop/nearby/presentation/viewmodel/NearbyViewModel.dart';
import 'package:near_drop/nearby/presentation/widgets/AnimatedFadeSwitcher.dart';
import 'package:near_drop/nearby/presentation/widgets/ManuallyConnectingBottomSheet.dart';
import 'package:near_drop/nearby/presentation/widgets/PlusingCircleLoader.dart';
import 'package:near_drop/tools/ui/FlexibleAppBar.dart';
import 'package:near_drop/tools/ui/ShapedMaterial.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';
import 'package:near_drop/transport/domain/enums/SendResponse.dart';
import 'package:near_drop/transport/presentation/TransportViewModel.dart';
import 'package:provider/provider.dart';
import '../../../Routes.dart';
import '../../../Runtime.dart';
import '../../../core/domain/entity/CommunicationInfo.dart';
import '../../../core/domain/entity/Device.dart';
import '../../../core/domain/enums/CommunicationState.dart';
import '../../../core/domain/enums/DeviceType.dart';
import '../../../core/domain/enums/ErrorState.dart';
import '../../../core/domain/enums/SuccessState.dart';
import '../../../l10n/gen/app_localizations.dart';

class NearbyPage extends StatelessWidget
{
    // Key, um Dialoge von überall anzuzeigen
    static final GlobalKey<NavigatorState> scaffoldKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NearbyViewModel>(
          create: (context) => NearbyViewModel(),
        ),
        ChangeNotifierProvider<TransportViewModel>(
            create: (context) => TransportViewModel()
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
                Builder(
                  builder: (context) {
                    return _appBar(context);
                  }
                ),
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
              ],
            ),
            _scanningAnimation(context) // Ladeanimation, wenn keine Geräte gefunden wurden
                .visible(context.watch<NearbyViewModel>().isInitializingFailed == false),
            _initializingNearbyUuidFailedView(context)
              .visible(context.watch<NearbyViewModel>().isInitializingFailed),
            Column(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                    _infoArea(context),
                    _bottomBar(context).visible(context.watch<NearbyViewModel>().isInitializingFailed == false),
                ],
            )
            .paddingAll(16)
            .safeArea()
          ],
        ),
      ),
    );
  }

  Widget _initializingNearbyUuidFailedView(BuildContext context) {
      return Column(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 28,
              ),
              Text(
                  AppLocalizations.of(context)!.core_initializing_error_text,
                  textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              FilledButton(onPressed: () {
                  context.read<NearbyViewModel>().initializeCore();
              }, child: Text(AppLocalizations.of(context)!.core_initializing_error_retry_button))
          ],
      ).centered().paddingSymmetric(horizontal: 40);
  }

  /// Ein Infobereich, der verschiedene Informationen anzeigt, wenn Probleme auftreten.
  Widget _infoArea(BuildContext context) {
      return AnimatedOpacity(
        duration: Duration(milliseconds: context.watch<NearbyViewModel>().isInfoAreaVisible ? 400 : 200),
        curve: context.watch<NearbyViewModel>().isInfoAreaVisible ? Curves.linearToEaseOut : Curves.easeIn,
        opacity: context.watch<NearbyViewModel>().isInfoAreaVisible ? 1 : 0,
        child: AnimatedScale(
          alignment: Alignment.bottomRight,
          duration: Duration(milliseconds: context.watch<NearbyViewModel>().isInfoAreaVisible ? 400 : 200),
          curve: context.watch<NearbyViewModel>().isInfoAreaVisible ? Curves.linearToEaseOut : Curves.easeIn,
          scale: context.watch<NearbyViewModel>().isInfoAreaVisible ? 1 : 0.9,
          child: Column(
              spacing: 0,
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                  _infoBar(context, AppLocalizations.of(context)!.no_internet_connection_info_bar_title, AppLocalizations.of(context)!.no_internet_connection_info_bar_subtitle, Icons.wifi_off_outlined)
                      .visible(!context.watch<NearbyViewModel>().isConnectedWithNetwork),
                  _infoBar(context, AppLocalizations.of(context)!.bluetooth_not_supported_info_bar_title, AppLocalizations.of(context)!.bluetooth_not_supported_info_bar_subtitle, Icons.bluetooth_disabled_outlined)
                      .paddingOnly(top: 4)
                      .visible(!context.watch<NearbyViewModel>().isBluetoothSupported),
                  _infoBar(context, AppLocalizations.of(context)!.bluetooth_no_permission_info_bar_title, AppLocalizations.of(context)!.bluetooth_no_permission_info_bar_subtitle, Icons.bluetooth_disabled_outlined)
                      .paddingOnly(top: 4)
                      .visible(!context.watch<NearbyViewModel>().hasBluetoothPermissions),
                  _infoBar(context, AppLocalizations.of(context)!.bluetooth_disabled_info_bar_title, AppLocalizations.of(context)!.bluetooth_disabled_info_bar_subtitle, Icons.bluetooth_disabled_outlined)
                      .paddingOnly(top: 4)
                      .visible(!context.watch<NearbyViewModel>().isBluetoothEnabled),
                  _infoBar(context, AppLocalizations.of(context)!.bluetooth_error_info_bar_title, AppLocalizations.of(context)!.bluetooth_error_info_bar_subtitle, Icons.bluetooth_disabled_outlined)
                      .paddingOnly(top: 4)
                      .visible(false),
                      //.visible(context.watch<NearbyViewModel>().isInfoMessagesButtonVisible),
              ],
          ).align(Alignment.bottomCenter),
        ),
      );
  }

  /// Zeigt eine Ladeanimation an, wenn nach Geräten gesucht wird und keine gefunden wurden.
  Widget _scanningAnimation(BuildContext context) {
      return IgnorePointer(
          ignoring: true,
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 600),
          opacity: context.watch<NearbyViewModel>().nearbyDevices.isEmpty ? 1 : 0,
          child: Stack(
              alignment: Alignment.center,
              children: [
                  PulsingCirclesLoader()
                      .opacity(0.2),
                  Icon(
                      Icons.sensors_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: Platform.isAndroid || Platform.isIOS ? 48 : 40,
                  )
              ],
          ).align(Alignment.center).paddingOnly(left: 32, right: 32, top: 110),
        ),
      );
  }

  /// Seitenleiste, der Informationen über die App anzeigt.
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
                ShapedMaterial(
                    shapePosition: ShapePosition.start,
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    child: ListTile(
                        title: Text(AppLocalizations.of(context)!.imprint_title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface),),
                        leading: Icon(Icons.info_outline),
                        iconColor: Theme.of(context).colorScheme.onSurface,
                    ),
                ),
                SizedBox(height: 4),
                ShapedMaterial(
                    shapePosition: ShapePosition.middle,
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    child: ListTile(
                        title: Text(AppLocalizations.of(context)!.data_privacy_title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface),),
                        leading: Icon(Icons.shield_outlined),
                        iconColor: Theme.of(context).colorScheme.onSurface,
                    ),
                ),
                SizedBox(height: 4),
                ShapedMaterial(
                    shapePosition: ShapePosition.end,
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    onTap: ()  {
                        showLicensePage(context: context);
                    },
                    child: ListTile(
                        title: Text(AppLocalizations.of(context)!.licenses_title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface),),
                        leading: Icon(Icons.verified_user_outlined),
                        iconColor: Theme.of(context).colorScheme.onSurface,
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

  /// Zeigt eine Gitteransicht der gefundenen Geräte an.
  Widget _nearbyDevicesGrid(BuildContext context, List<Device> devices) {
      if (Platform.isWindows || Platform.isWindows || Platform.isLinux) {
          return SliverToBoxAdapter(
              child: Wrap(
                  children: [
                      for (Device device in devices)
                          _deviceItem(context, device).paddingOnly(right: 12, bottom: 12)
                  ],
              ),
          );
      }

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

  /// Erstellt ein Widget, das die Informationen eines Geräts anzeigt.
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
      ).sized(height: 88, width: (Platform.isWindows || Platform.isMacOS || Platform.isLinux) ? 190 : double.infinity)
    );
  }

  /// Gibt den Text für den Kommunikationsstatus zurück.
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

  /// Erstellt die App-Leiste mit dem Titel und den Aktionen.
  Widget _appBar(BuildContext context) {
    return FlexibleAppBar(
      title: AppLocalizations.of(context)!.app_name,
      leading: IconButton(
          icon: Icon(Icons.menu,),
          tooltip: AppLocalizations.of(context)!.nearby_page_menu_icon_tooltip,
          onPressed: () {
              Scaffold.of(context).openDrawer();
          },
      ),
      actions: [
          IconButton(onPressed: () {
            Navigator.of(context).pushNamed(Routes.help);
          }, icon: Icon(Icons.help_outline), tooltip: AppLocalizations.of(context)!.nearby_page_help_button_tooltip),
        IconButton(onPressed: () {
        Navigator.of(context).pushNamed(Routes.guestSettings);
      }, icon: Icon(Icons.person_outline), tooltip: AppLocalizations.of(context)!.nearby_page_account_icon_tooltip)
      ],
    );
  }

  /// Erstellt die Leiste mit Informationen am unteren Rand der Seite.
  Widget _bottomBar(BuildContext context) {
    return Row(
      spacing: 0,
        children: [
      Expanded(
        flex: (Platform.isAndroid || Platform.isIOS) ? 1 : 0,
        child: Material(
          borderRadius: BorderRadius.circular(28),
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: AnimatedFadeSwitcher(
              duration: Duration(milliseconds: 400),
              child: context.watch<NearbyViewModel>().isInitializingNearbyUuid ?
                  Padding(
                    key: ValueKey(0),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                        spacing: 16,
                        children: [
                            CircularProgressIndicator(strokeWidth: 3, strokeCap: StrokeCap.round,).sized(height: 20, width: 20),
                            Text(
                                AppLocalizations.of(context)!.core_initializing_loading_text,
                                style: Theme.of(context).textTheme.labelLarge,
                            )
                        ],
                    ),
                  ) :
              Padding(
                key: ValueKey(1),
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                        text: context.watch<NearbyViewModel>().firstname,
                                        style: TextStyle(color: Theme.of(context).colorScheme.primary)
                                    ),
                                    TextSpan(
                                        text: ".",
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
                                    ),
                                ]),
                        ).expanded(flex: (Platform.isAndroid || Platform.isIOS) ? 1 : 0),
                    ],
                ),
              ),
          ),
        )
        .sized(height: 56)
        .paddingOnly(right: 8),
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
          ),
        child: IconButton(style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surfaceContainer),
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: context.watch<NearbyViewModel>().isInitializingNearbyUuid || !context.watch<NearbyViewModel>().isNearbyUuidInitialized ? null : () {
                context.read<NearbyViewModel>().setDeviceNotFoundBalloonVisibility(false);
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
            },
            icon: Icon(Icons.qr_code_2)
        )
            .sized(width: 56, height: 56)
            .tooltip(
            message: AppLocalizations.of(context)!.nearby_page_manual_connection_tooltip,
            preferBelow: false,
        ),
      ),
    Badge(
        label: Text("!", style: TextStyle(fontSize: 14),),
        isLabelVisible: !context.watch<NearbyViewModel>().isInfoAreaVisible,
        offset: Offset(0, 0),
      child: Material(
          clipBehavior: Clip.hardEdge,
          color: context.watch<NearbyViewModel>().isInfoAreaVisible ? Theme.of(context).colorScheme.inverseSurface : Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(28),
          child: Icon(
              context.watch<NearbyViewModel>().isInfoAreaVisible ? Icons.close : Icons.notifications_outlined,
              color: context.watch<NearbyViewModel>().isInfoAreaVisible ? Theme.of(context).colorScheme.onInverseSurface : Theme.of(context).colorScheme.onErrorContainer,
          ).clickable(onTap: () {
                context.read<NearbyViewModel>().toggleInfoMessagesVisibility();
          })
      )
        .sized(height: 56, width: 56),
    ).paddingOnly(left: 8).visible(context.watch<NearbyViewModel>().isInfoMessagesButtonVisible)
    ]);
  }

  /// Erstellt eine Infomitteilung mit einem Titel, Untertitel und einem Icon.
  Widget _infoBar(BuildContext context, String title, String subtitle, IconData icon) {
      return Material(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
          child: Row(
              spacing: 12,
              children: [
                  Icon(
                      icon,
                      color: Theme.of(context).colorScheme.error,
                  ),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(
                              title,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                          ),
                          Text(
                              subtitle,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
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

  /// Zeigt einen Dialog an, um den Transport mit einem Gerät abzubrechen.
  Widget _cancelTransportDialog(BuildContext context, Device device) {
      return AlertDialog(
        key: device.cancelTransportDialogKey,
        actionsPadding: EdgeInsets.only(bottom: 16, right: 24, left: 24),
        title: Text(
            AppLocalizations.of(context)!.cancel_transport_title(device.firstname),
        ),
        actions: [
            TextButton(
                onPressed: () {
                    Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.cancel_transport_cancel_dialog_button,)
            ),
            TextButton(
                onPressed: () {
                    Navigator.of(context).pop();
                    context.read<TransportViewModel>().cancelTransport(device);
                },
                child: Text(AppLocalizations.of(context)!.cancel_transport_confirm_dialog_button)
            )
        ],
      );
  }

  /// Zeigt einen Dialog an, um Dateien an ein Gerät zu senden.
  Widget _sendDialog(BuildContext context, Device device) {
      return AlertDialog(
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
                    color: Theme.of(context).brightness == Brightness.light ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surfaceContainer,
                    child: ListTile(
                        leading: Icon(Icons.insert_photo_outlined, color: Theme.of(context).colorScheme.onSurface,),
                        title: Text(
                            AppLocalizations.of(context)!.send_dialog_media_label,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
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
                      color: Theme.of(context).brightness == Brightness.light ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surfaceContainer,
                      child: ListTile(
                          leading: Icon(Icons.file_copy_outlined, color: Theme.of(context).colorScheme.onSurface,),
                          title: Text(
                              AppLocalizations.of(context)!.send_dialog_files_label,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
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

  /// Sendet die ausgewählten Dateien an das angegebene Gerät.
  Future<void> _handleSendFiles(BuildContext context, Device device, List<File> files) async {
      SendResponse sendResponse = await context.read<TransportViewModel>().sendFiles(device, files);

      String message = "";
      switch (sendResponse) {
        case SendResponse.receiverError:
            message = AppLocalizations.of(context)!.snackbar_message_receiver_error;
            break;
        case SendResponse.fileAccessError:
            message = AppLocalizations.of(context)!.snackbar_message_file_access_error;
            break;
        case SendResponse.connectionError:
            message = AppLocalizations.of(context)!.snackbar_message_connection_error;
            break;
        case SendResponse.timeout:
            message = AppLocalizations.of(context)!.snackbar_message_timeout;
            break;
        default:
              break;
      }

      if (message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(message),
                  duration: Duration(seconds: 6),
                  action: SnackBarAction(
                      label: AppLocalizations.of(context)!.snackbar_retry_action,
                      onPressed: () {
                          _handleSendFiles(context, device, files);
                      }
                  ),
              )
          );
      }
  }
}
