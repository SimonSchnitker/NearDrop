import 'dart:io';
import 'package:flutter/material.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';
import '../../../l10n/gen/app_localizations.dart';

class ReceivedFilesLocationInfoView extends StatelessWidget
{
    @override
  Widget build(BuildContext context) {
        return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                Text(
                    AppLocalizations.of(context)!.help_page_received_files_bottom_sheet_title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w500)
                ),
                SizedBox(height: 32),
                if (Platform.isAndroid || Platform.isIOS) _buildMediaTile(context),
                if (Platform.isAndroid || Platform.isIOS) SizedBox(height: 8),
                if (Platform.isAndroid || Platform.isIOS) _buildOtherFilesTile(context),
                if (Platform.isWindows || Platform.isMacOS) _buildDesktopTile(context),
            ],
        ).safeArea().paddingOnly(left: 16, right: 16, bottom: 16);
    }

    Widget _buildMediaTile(BuildContext context) {
        return Row(
            children: [
                CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                    radius: 36,
                    child: Icon(
                        Icons.image_outlined,
                        size: 28,
                    ),
                ),
                ListTile(
                    title: Text(
                        AppLocalizations.of(context)!.help_page_received_files_bottom_sheet_media_label,
                        style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(AppLocalizations.of(context)!.help_page_received_files_bottom_sheet_media_content),
                ).expanded()
            ],
        );
    }

    Widget _buildOtherFilesTile(BuildContext context) {
        return Row(
            children: [
                CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                    radius: 36,
                    child: Icon(
                        Icons.insert_drive_file_outlined,
                        size: 28,
                    ),
                ),
                ListTile(
                    title: Text(
                        AppLocalizations.of(context)!.help_page_received_files_bottom_sheet_files_label,
                        style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(AppLocalizations.of(context)!.help_page_received_files_bottom_sheet_files_content),
                ).expanded()
            ],
        );
    }

    Widget _buildDesktopTile(BuildContext context) {
        return Row(
            children: [
                CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                    radius: 36,
                    child: Icon(
                        Icons.image_outlined,
                        size: 28,
                    ),
                ),
                ListTile(
                    title: Text(
                        AppLocalizations.of(context)!.help_page_received_files_bottom_sheet_files_title_desktop,
                        style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(AppLocalizations.of(context)!.help_page_received_files_bottom_sheet_files_content_desktop),
                ).expanded()
            ],
        );
    }
}