import 'package:flutter/material.dart';
import 'package:near_drop/Routes.dart';
import 'package:near_drop/help/presentation/ReceivedFilesLocationInfoView.dart';
import 'package:near_drop/tools/ui/FlexibleAppBar.dart';
import 'package:near_drop/tools/ui/ShapedMaterial.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../Runtime.dart';
import 'HelpViewModel.dart';
import '../../../l10n/gen/app_localizations.dart';

class HelpPage extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return ChangeNotifierProvider(
            create: (context) => HelpViewModel(),
            builder: (context, child) => Scaffold(
                body: CustomScrollView(
                    physics: PageScrollPhysics(),
                    slivers: [
                        FlexibleAppBar(title: AppLocalizations.of(context)!.help_page_title),
                        SliverToBoxAdapter(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(
                                        AppLocalizations.of(context)!.help_page_installation_title,
                                        style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.primary),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                        AppLocalizations.of(context)!.help_page_installation_description,
                                        style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    SizedBox(height: 16),
                                    _buildAndroidItem(context),
                                    SizedBox(height: 4),
                                    _buildiOSItem(context),
                                    SizedBox(height: 4),
                                    _buildWindowsItem(context),
                                    SizedBox(height: 32),
                                    Text(
                                        AppLocalizations.of(context)!.help_page_faq_title,
                                        style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.primary),
                                    ),
                                    SizedBox(height: 8),
                                    ShapedMaterial(
                                        shapePosition: ShapePosition.only,
                                        onTap: () {
                                            showModalBottomSheet(
                                                context: context,
                                                builder: (_) => ReceivedFilesLocationInfoView(),
                                                showDragHandle: true,
                                                sheetAnimationStyle: AnimationStyle(
                                                    duration: Duration(milliseconds: 380),
                                                    reverseDuration: Duration(milliseconds: 250),
                                                )
                                            );
                                        },
                                        child: ListTile(
                                            leading: Icon(Icons.download_outlined),
                                            title: Text(AppLocalizations.of(context)!.help_page_faq_received_files_question),
                                        )
                                    )
                                ],
                            ).paddingAll(16),
                        ),
                    ],
                ),
            ),
        );
    }

    Widget _buildAndroidItem(BuildContext context) {
        return Material(
            clipBehavior: Clip.hardEdge,
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4), top: Radius.circular(24)),
            child: ListTile(
                leading: Icon(Icons.android),
                trailing: Icon(Icons.open_in_new),
                title: Text(AppLocalizations.of(context)!.help_page_install_on_android_title),
                subtitle: Text(AppLocalizations.of(context)!.help_page_install_on_android_content),
                onTap: () async {
                    await launchUrlString(Runtime.androidAppUrl, mode: LaunchMode.externalApplication);
                },
            )
        );
    }

    Widget _buildiOSItem(BuildContext context) {
        return Material(
            clipBehavior: Clip.hardEdge,
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(4),
            child: ListTile(
                leading: Icon(Icons.apple),
                trailing: Icon(Icons.open_in_new),
                title: Text(AppLocalizations.of(context)!.help_page_install_on_apple_title),
                subtitle: Text(AppLocalizations.of(context)!.help_page_install_on_apple_content),
                onTap: () async {
                    await launchUrlString(Runtime.iosAppUrl, mode: LaunchMode.externalApplication);
                },
            )
        );
    }

    Widget _buildWindowsItem(BuildContext context) {
        return Material(
            clipBehavior: Clip.hardEdge,
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24), top: Radius.circular(4)),
            child: ListTile(
                leading: Icon(Icons.desktop_windows_outlined),
                trailing: Icon(Icons.open_in_new),
                title: Text(AppLocalizations.of(context)!.help_page_install_on_windows_title),
                subtitle: Text(AppLocalizations.of(context)!.help_page_install_on_windows_content),
                onTap: () async {
                    await launchUrlString(Runtime.windowsAppUrl, mode: LaunchMode.externalApplication);
                },
            )
        );
    }
}