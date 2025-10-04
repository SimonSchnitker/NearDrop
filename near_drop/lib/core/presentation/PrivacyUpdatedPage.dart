import 'package:flutter/material.dart';
import 'package:near_drop/Routes.dart';
import 'package:near_drop/core/presentation/viewmodel/PrivacyUpdatedViewModel.dart';
import 'package:near_drop/tools/ui/ShapedMaterial.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../Runtime.dart';
import '../../tools/ui/LoadingOverlay.dart';

class PrivacyUpdatedPage extends StatelessWidget
{
    @override
    Widget build(BuildContext context) {
        return ChangeNotifierProvider(
            create: (_) => PrivacyUpdatedViewModel(),
          builder: (context, _) => Scaffold(
              body: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      Icon(
                          Icons.privacy_tip_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                      ).align(Alignment.topLeft),
                      SizedBox(height: 40),
                      Text(
                          AppLocalizations.of(context)!.privacy_updated_title,
                          style: Theme.of(context).textTheme.displayMedium!.copyWith(fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 32),
                      Text(
                          AppLocalizations.of(context)!.privacy_updated_subtitle,
                          style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: 16),
                      ShapedMaterial(
                          shapePosition: ShapePosition.only,
                          child: Row(
                              spacing: 16,
                              children: [
                                  Icon(Icons.open_in_new, color: Theme.of(context).colorScheme.primary,),
                                  Text(AppLocalizations.of(context)!.privacy_updated_read_button, style: TextStyle(color: Theme.of(context).colorScheme.primary).copyWith(fontWeight: FontWeight.w500),)
                              ],
                          ).paddingAll(16),
                          onTap: () async {
                              await launchUrlString(Runtime.privacyPolicyUrl, mode: LaunchMode.externalApplication);
                          },
                      ),
                      Spacer(),
                      FilledButton(
                          onPressed: () async {
                              await context.read<PrivacyUpdatedViewModel>().acceptNewPrivacyPolicy();
                              Navigator.of(context).pushNamedAndRemoveUntil(Routes.nearby, (route) => false);
                          },
                          child: Text(AppLocalizations.of(context)!.privacy_updated_accept_button),
                      ).sized(height: 60),
                      SizedBox(height: 8),
                      TextButton(onPressed: () async {
                          await _handleDeleteAccount(context);
                      }, child: Text(AppLocalizations.of(context)!.privacy_updated_delete_account_button))
                  ],
              )
                  .safeArea()
                  .paddingAll(16),
          ),
        );
    }

    Future<void> _handleDeleteAccount(BuildContext context) async
    {
        try
        {
            await showLoadingOverlay(context, context.read<PrivacyUpdatedViewModel>().deleteAccount);
            Navigator.of(context).pushNamedAndRemoveUntil(Routes.welcome, (route) => false); // Zurück zur Willkommensseite
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.account_deleted_snackbar_content)
                ));
        }
        catch (e)
        {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.account_delete_error_snackbar_content)
                ));
        }
    }
}