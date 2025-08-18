import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:near_drop/Runtime.dart';
import 'package:near_drop/tools/ui/ShapedMaterial.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'Routes.dart';
import 'l10n/gen/app_localizations.dart';

class WelcomePage extends StatelessWidget
{
    @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Icon(
                    Icons.wifi_tethering_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                ),
                /*
                Material(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(24),
                    child: Text(
                        AppLocalizations.of(context)!.welcome_preview_info_text,
                        style: Theme.of(context).textTheme.labelLarge,
                    ).paddingSymmetric(horizontal: 24, vertical: 12),
                ),
                 */
                SizedBox(height: 40),
                Text(
                    AppLocalizations.of(context)!.app_name,
                    style: Theme.of(context).textTheme.displayMedium!.copyWith(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4),
                Text(
                    AppLocalizations.of(context)!.welcome_subtitle,
                    style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: 16),
                Expanded(
                    child: Container(
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(24),
                        ),
                        child: Lottie.asset(Theme.of(context).brightness == Brightness.light ? "assets/lottie/welcome_animation_light.json" : "assets/lottie/welcome_animation_dark.json")
                    )
                ),
                SizedBox(height: 16),
                Row(
                    children: [
                        TextButton(onPressed: () {
                            showModalBottomSheet(
                                context: context,
                                builder: (context) => _appInfoDialog(context),
                                showDragHandle: true,
                                isScrollControlled: true,
                                sheetAnimationStyle: AnimationStyle(
                                    duration: Duration(milliseconds: 350),
                                    reverseDuration: Duration(milliseconds: 250),
                                )
                            );
                        }, child: Text(AppLocalizations.of(context)!.app_info_button)),
                        Spacer(),
                        FilledButton(
                            onPressed: () {
                                Navigator.pushNamed(context, Routes.guestLogin);
                            }, child: Text(AppLocalizations.of(context)!.continue_button)
                        ),
                    ],
                )
            ],
        )
        .safeArea()
        .paddingAll(16)
    );
  }
}

Widget _appInfoDialog(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
            Text(
                AppLocalizations.of(context)!.app_info_title,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w500)
            )
                .align(Alignment.center),
            SizedBox(height: 16),
            ShapedMaterial(
                shapePosition: ShapePosition.start,
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                onTap: () async {
                    await launchUrlString(Runtime.imprintUrl, mode: LaunchMode.externalApplication);
                },
                child: ListTile(
                    title: Text(AppLocalizations.of(context)!.imprint_title),
                    subtitle: Text(AppLocalizations.of(context)!.imprint_subtitle),
                    leading: Icon(Icons.info_outline),
                ),
            ),
            SizedBox(height: 4),
            ShapedMaterial(
                shapePosition: ShapePosition.end,
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                onTap: () {
                    showLicensePage(context: context);
                },
                child: ListTile(
                    title: Text(AppLocalizations.of(context)!.licenses_title),
                    subtitle: Text(AppLocalizations.of(context)!.licenses_subtitle),
                    leading: Icon(Icons.verified_user_outlined),
                ),
            ),
            SizedBox(height: 16),
            Material(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.all(Radius.circular(24)),
                child: ListTile(
                    title: Text(AppLocalizations.of(context)!.version_title),
                    subtitle: Text(Runtime.appVersion.toString()),
                    leading: Icon(Icons.install_mobile_outlined),
                ),
            )
        ],
    )
    .safeArea()
    .paddingOnly(left: 16, right: 16, bottom: 16);
}