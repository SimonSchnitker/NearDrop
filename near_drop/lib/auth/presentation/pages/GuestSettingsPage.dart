import 'package:flutter/material.dart';
import 'package:near_drop/Routes.dart';
import 'package:near_drop/tools/ui/FlexibleAppBar.dart';
import 'package:near_drop/tools/ui/LoadingOverlay.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';
import 'package:provider/provider.dart';
import '../viewmodel/GuestSettingsViewModel.dart';
import '../../../l10n/gen/app_localizations.dart';

class GuestSettingsPage extends StatelessWidget {
  const GuestSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
      return ChangeNotifierProvider(
          create : (context) => GuestSettingsViewModel(),
          builder: (context, child) => Scaffold(
              body: CustomScrollView(
                  physics: PageScrollPhysics(),
                  slivers: [
                      FlexibleAppBar(title: AppLocalizations.of(context)!.account_page_title,),
                      SliverToBoxAdapter(
                          child: Column(
                              children: [
                                  _buildChangeNameView(context),
                                  SizedBox(height: 16,),
                                  _buildShowAccuntDataButton(context),
                                  SizedBox(height: 4,),
                                  _buildDeleteAccountButton(context),
                              ],
                          ).paddingAll(16),
                      )
                  ],
              ),
          )
      );
    }

    Widget _buildChangeNameView(BuildContext context) {
        return Material(
            clipBehavior: Clip.hardEdge,
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            child: ListTile(
                leading: Icon(Icons.person_outlined),
                title: Text(AppLocalizations.of(context)!.account_page_change_firstname_label),
                subtitle: Text(
                    context.watch<GuestSettingsViewModel>().firstname
                ),
                onTap: () {
                    context.read<GuestSettingsViewModel>().firstnameController.clear();
                    showDialog(
                        context: context,
                        builder: (_) => _changeFirstnameDialog(context),
                    );
                },
            )
        );
    }

    Widget _buildShowAccuntDataButton(BuildContext context) {
        return Material(
            clipBehavior: Clip.hardEdge,
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(4)),
            child: ListTile(
                leading: Icon(Icons.info_outline),
                trailing: Icon(Icons.chevron_right),
                title: Text(AppLocalizations.of(context)!.account_page_show_my_data_label),
                onTap: () {
                    Navigator.pushNamed(context, Routes.savedUserData);
                },
            )
        );
    }

    Widget _buildDeleteAccountButton(BuildContext context) {
        return Material(
            clipBehavior: Clip.hardEdge,
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.vertical(top: Radius.circular(4), bottom: Radius.circular(24)),
            child: ListTile(
                leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error,),
                title: Text(AppLocalizations.of(context)!.account_page_delete_account_label, style: TextStyle(color: Theme.of(context).colorScheme.error),),
                onTap: () {
                    showDialog(context: context, builder: (_) => _deleteAccountDialog(context));
                },
            )
        );
    }

    Widget _changeFirstnameDialog(BuildContext context) {
        return AlertDialog(
            title: Text(AppLocalizations.of(context)!.account_page_change_firstname_dialog_title),
            content: TextField(
                autofocus: true,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                    ),
                    labelText: AppLocalizations.of(context)!.account_page_change_firstname_textfield_label,
                ),
                maxLength: 12,
                controller: context.read<GuestSettingsViewModel>().firstnameController,
                autofillHints: [AutofillHints.name],
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.text,
            ),
            actions: [
                TextButton(
                    onPressed: () {
                        Navigator.of(context).pop();
                    },
                    child: Text(AppLocalizations.of(context)!.cancel_button),
                ),
                TextButton(
                    onPressed: () {
                        // Logik zum Ändern des Vornamens
                        Navigator.of(context).pop();
                        context.read<GuestSettingsViewModel>().updateFirstname();
                    },
                    child: Text(AppLocalizations.of(context)!.account_page_change_firstname_dialog_save_button),
                ),
            ],
        );
    }

    Widget _deleteAccountDialog(BuildContext context) {
        return AlertDialog(
            title: Text(AppLocalizations.of(context)!.account_page_delete_account_dialog_title),
            content: Text(AppLocalizations.of(context)!.account_page_delete_account_dialog_content),
            actions: [
                TextButton(
                    onPressed: () {
                        Navigator.of(context).pop();
                    },
                    child: Text(AppLocalizations.of(context)!.cancel_button),
                ),
                TextButton(
                    onPressed: () async {
                        _handleLogout(context);
                    },
                    child: Text(AppLocalizations.of(context)!.account_page_delete_account_dialog_delete_button, style: TextStyle(color: Theme.of(context).colorScheme.error),),
                ),
            ],
        );
    }

    Future<void> _handleLogout(BuildContext context) async
    {
        Navigator.of(context).pop(); // Dialog schließen
        await showLoadingOverlay(context, context.read<GuestSettingsViewModel>().deleteAccount);
        Navigator.of(context).pushNamedAndRemoveUntil(Routes.welcome, (route) => false); // Zurück zur Willkommensseite
    }
}