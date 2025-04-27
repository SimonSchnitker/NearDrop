import 'package:flutter/material.dart';
import 'package:near_drop/nearby/presentation/viewmodel/NearbyViewModel.dart';
import 'package:near_drop/tools/ui/FlexibleAppBar.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';
import 'package:provider/provider.dart';
import '../../../Runtime.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NearbyPage extends StatelessWidget
{
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NearbyViewModel(),
      builder: (context, child) => Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              physics: PageScrollPhysics(),
              slivers: [_appBar(context), SliverToBoxAdapter(child: SizedBox(height: 1000))],
            ),
            _bottomBar(context)
                .safeArea()
                .paddingAll(16)
                .align(Alignment.bottomCenter),
            FilledButton(onPressed: () {
              context.read<NearbyViewModel>().a();
            }, child: Text("BLE")).centered()
          ],
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    return FlexibleAppBar(
      title: AppLocalizations.of(context)!.app_name,
      leading: IconButton(onPressed: () {

      }, icon: Icon(Icons.menu), tooltip: AppLocalizations.of(context)!.nearby_page_menu_icon_tooltip),
      actions: [
        IconButton(onPressed: () {

      }, icon: Icon(Icons.person_outline), tooltip: AppLocalizations.of(context)!.nearby_page_account_icon_tooltip)
      ],
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Row(
      spacing: 8,
        children: [
      Expanded(
        child: Material(
          borderRadius: BorderRadius.circular(28),
          color: Theme.of(context).colorScheme.surfaceContainer,
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
                        text: Runtime.firstname,
                        style: TextStyle(color: Theme.of(context).colorScheme.primary)
                    ),
                    TextSpan(
                        text: ".",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
                    ),
                  ]),
              ),
            ],
          )
            .paddingSymmetric(horizontal: 16)
        )
        .sized(height: 56),
      ),
      Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        child: IconButton(
          tooltip: AppLocalizations.of(context)!.nearby_page_manual_connection_tooltip,
            onPressed: () {

        }, icon: Icon(Icons.qr_code_2)),
      )
      .sized(height: 56, width: 56)
    ]);
  }
}
