import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:near_drop/auth/domain/model/UserData.dart';
import 'package:near_drop/auth/presentation/viewmodel/SavedUserDataViewModel.dart';
import 'package:near_drop/tools/ui/FlexibleAppBar.dart';
import 'package:near_drop/tools/ui/LoadingOverlay.dart';
import 'package:near_drop/tools/ui/ShapedMaterial.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../l10n/gen/app_localizations.dart';

class SavedUserDataPage extends StatelessWidget
{
    @override
  Widget build(BuildContext context) {
        return ChangeNotifierProvider(
            create: (context) => SavedUserDataViewModel(),
            builder: (context, child) => Scaffold(
              body: CustomScrollView(
                  physics: PageScrollPhysics(),
                  slivers: [
                      FlexibleAppBar(title: AppLocalizations.of(context)!.saved_data_page_title),
                      SliverToBoxAdapter(
                          child: SafeArea(
                              top: false,
                            child: context.watch<SavedUserDataViewModel>().userData == null
                                ? _buildFetchUserData(context)
                                : _buildUserData(context),
                          ),
                      )
                  ],
              ),
          ),
        );
    }

    Widget _buildFetchUserData(BuildContext context) {
        return ShapedMaterial(
            shapePosition: ShapePosition.only,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                Text(AppLocalizations.of(context)!.saved_data_page_description),
                SizedBox(height: 16),

                FilledButton(onPressed: () {
                    _handleGetUserData(context);
                }, child: Text(AppLocalizations.of(context)!.saved_data_page_fetch_data_button))
            ],
            ).paddingAll(16)
        ).paddingAll(16);
    }

    Widget _buildUserData(BuildContext context) {
        UserData userData = context.watch<SavedUserDataViewModel>().userData!;

        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
                ShapedMaterial(
                    shapePosition: ShapePosition.start,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                                AppLocalizations.of(context)!.saved_data_page_login_data_label,
                                style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.primary),
                            ).paddingOnly(left: 16, top: 16, right: 16),
                            ListTile(
                                title: Text(AppLocalizations.of(context)!.saved_data_page_user_id_label),
                                subtitle: Text(userData.userId),
                            ),
                            ListTile(
                                title: Text(AppLocalizations.of(context)!.saved_data_page_created_at_label),
                                subtitle: Text(userData.createdAt.toIso8601String()),
                            ),
                            if (userData.updatedAt != null)
                                ListTile(
                                    title: Text(AppLocalizations.of(context)!.saved_data_page_updated_at_label),
                                    subtitle: Text(userData.updatedAt!.toIso8601String()),
                                ),
                            if (userData.lastSignInAt != null)
                                ListTile(
                                    title: Text(AppLocalizations.of(context)!.saved_data_page_last_sign_in_at_label),
                                    subtitle: Text(userData.lastSignInAt!.toIso8601String()),
                                ),
                        ],
                    )
                ),
                ShapedMaterial(
                shapePosition: ShapePosition.middle,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(AppLocalizations.of(context)!.saved_data_page_sessions_label,
                            style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.primary),
                        ).paddingOnly(left: 16, top: 16, right: 16),
                        for (var session in userData.sessions)
                            ListTile(
                                title: Text(AppLocalizations.of(context)!.saved_data_page_sessions_ip_label),
                                subtitle: Text(session.ipAddress),
                            )
                        ],
                    )
                ),
                ShapedMaterial(
                    shapePosition: ShapePosition.middle,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(AppLocalizations.of(context)!.saved_data_page_privacy_policy_consents_label,
                                style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.primary),
                            ).paddingOnly(left: 16, top: 16, right: 16),
                            for (var consent in userData.privacyPolicyConsents)
                                ListTile(
                                    title: Text("${AppLocalizations.of(context)!.version_title} ${consent.version}"),
                                    subtitle: Text(AppLocalizations.of(context)!.saved_data_page_privacy_policy_consents_accepted_at_label(consent.acceptedAt.toIso8601String())),
                                )
                        ],
                    ),
                ),
                ShapedMaterial(
                    shapePosition: ShapePosition.end,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(AppLocalizations.of(context)!.saved_data_page_terms_of_use_consents_label,
                                style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.primary),
                            ).paddingOnly(left: 16, top: 16, right: 16),
                            for (var consent in userData.termsOfUseConsents)
                                ListTile(
                                    title: Text("${AppLocalizations.of(context)!.version_title} ${consent.version}"),
                                    subtitle: Text(AppLocalizations.of(context)!.saved_data_page_terms_of_use_consents_accepted_at_label(consent.acceptedAt.toIso8601String())),
                                )
                        ],
                    ),
                ),
            ],
        ).paddingAll(16);
    }

    Future<void> _handleGetUserData(BuildContext context) async
    {
        try
        {
            await showLoadingOverlay(context, context.read<SavedUserDataViewModel>().getSavedUserData);
        }
        catch (e)
        {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.saved_data_page_fetch_data_error_message))
            );
        }
    }
}