import 'package:flutter/material.dart';
import 'package:near_drop/Runtime.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';

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
                Material(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                    child: Text(
                        AppLocalizations.of(context)!.welcome_preview_info_text,
                    ).paddingSymmetric(horizontal: 16, vertical: 12),
                ),
                SizedBox(height: 24),
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
                    child: Center(
                        child: Container(
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(24),
                            ),
                            child: Container(),
                        ),
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
                style: Theme.of(context).textTheme.headlineSmall
            )
                .align(Alignment.center),
            SizedBox(height: 16),
            Material(
                color: Theme.of(context).colorScheme.surfaceContainerHigh.withOpacity(0.5),
                borderRadius: BorderRadius.all(Radius.circular(24)),
                clipBehavior: Clip.hardEdge,
                child: Column(
                    children: [
                        ListTile(
                            title: Text(AppLocalizations.of(context)!.imprint_title),
                            subtitle: Text(AppLocalizations.of(context)!.imprint_subtitle),
                            leading: Icon(Icons.info_outline),
                            onTap: () {

                            },
                        ),
                        ListTile(
                            title: Text(AppLocalizations.of(context)!.data_privacy_title),
                            subtitle: Text(AppLocalizations.of(context)!.data_privacy_subtitle),
                            leading: Icon(Icons.shield_outlined),
                            onTap: () {

                            },
                        ),
                        ListTile(
                            title: Text(AppLocalizations.of(context)!.licenses_title),
                            subtitle: Text(AppLocalizations.of(context)!.licenses_subtitle),
                            leading: Icon(Icons.verified_user_outlined),
                            onTap: () {

                            },
                        )
                    ],
                ),
            ),
            SizedBox(height: 16),
            Material(
                color: Theme.of(context).colorScheme.surfaceContainerHigh.withOpacity(0.5),
                borderRadius: BorderRadius.all(Radius.circular(24)),
                child: ListTile(
                    title: Text(AppLocalizations.of(context)!.version_title),
                    subtitle: Text(Runtime.getVersionString()),
                    leading: Icon(Icons.install_mobile_outlined),
                ),
            )
        ],
    )
    .safeArea()
    .paddingOnly(left: 16, right: 16, bottom: 16);
}