import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:near_drop/tools/ui/FlexibleAppBar.dart';
import 'package:near_drop/tools/ui/ShapedMaterial.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../l10n/gen/app_localizations.dart';

class SavedUserDataPage extends StatelessWidget
{
    @override
  Widget build(BuildContext context) {
        DateTime createdAt = DateTime.tryParse(Supabase.instance.client.auth.currentUser!.createdAt) ?? DateTime.now();
        DateTime lastSignInAt = DateTime.tryParse(Supabase.instance.client.auth.currentUser!.lastSignInAt ?? "") ?? DateTime.now();
        DateTime updatedAt = DateTime.tryParse(Supabase.instance.client.auth.currentUser!.updatedAt ?? "") ?? DateTime.now();

        return Scaffold(
            body: CustomScrollView(
                physics: PageScrollPhysics(),
                slivers: [
                    FlexibleAppBar(title: AppLocalizations.of(context)!.saved_data_page_title),
                    SliverToBoxAdapter(
                        child: Column(
                            children: [
                                Text(AppLocalizations.of(context)!.saved_data_page_description),
                                SizedBox(height: 16),
                                ShapedMaterial(
                                    shapePosition: ShapePosition.only,
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Text(
                                                AppLocalizations.of(context)!.saved_data_page_login_data_label,
                                                style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.primary),
                                            ).paddingOnly(left: 16, top: 16, right: 16),
                                            ListTile(
                                                title: Text(AppLocalizations.of(context)!.saved_data_page_created_at_label),
                                                subtitle: Text(DateFormat("dd.MM.yyyy HH:mm:ss").format(createdAt)),
                                            ),
                                            ListTile(
                                                title: Text(AppLocalizations.of(context)!.saved_data_page_updated_at_label),
                                                subtitle: Text(DateFormat("dd.MM.yyyy HH:mm:ss").format(updatedAt)),
                                            ),
                                            ListTile(
                                                title: Text(AppLocalizations.of(context)!.saved_data_page_last_sign_in_at_label),
                                                subtitle: Text(DateFormat("dd.MM.yyyy HH:mm:ss").format(lastSignInAt)),
                                            ),
                                        ],
                                    )
                                )
                            ],
                        ).paddingAll(16),
                    )
                ],
            ),
        );
  }
}