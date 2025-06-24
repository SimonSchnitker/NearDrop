import 'dart:io';

import 'package:flutter/material.dart';
import 'package:near_drop/Runtime.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../l10n/gen/app_localizations.dart';

class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
        title: Text(AppLocalizations.of(context)!.required_update_page_title),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              Spacer(),
              Material(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(60),
                  child: Icon(
                      Icons.notifications_outlined,
                      size: 60,
                  ),
              ).sized(width: 120, height: 120).align(Alignment.center),
              SizedBox(height: 32),
              Text(
                  AppLocalizations.of(context)!.required_update_page_content,
                  textAlign: TextAlign.center,
              ),
              Spacer(),
              FilledButton(
                  onPressed: () {
                    _handleUpdateClicked(context);
                  },
                  child: Text(AppLocalizations.of(context)!.required_update_page_button),
              ).sized(height: 60),
          ],
      ).paddingAll(16).safeArea(),
    );
  }

  Future<void> _handleUpdateClicked(BuildContext context) async {
      String url = "";
      if (Platform.isAndroid) {
          url = Runtime.androidAppUrl;
      } else if (Platform.isIOS || Platform.isMacOS) {
          url = Runtime.iosAppUrl;
      } else if (Platform.isWindows) {
          url = Runtime.windowsAppUrl;
      }

      await launchUrlString(url, mode: LaunchMode.externalApplication);
  }
}