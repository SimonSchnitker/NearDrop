import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:near_drop/Runtime.dart';
import 'package:near_drop/tools/PermissionHelper.dart';
import 'package:near_drop/tools/ui/FlexibleAppBar.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';
import 'package:provider/provider.dart';
import 'package:near_drop/auth/presentation/viewmodel/GuestLoginViewModel.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../Routes.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../tools/ui/LoadingOverlay.dart';

class GuestLoginPage extends StatelessWidget
{
    @override
    Widget build(BuildContext context) {
        return ChangeNotifierProvider(
            create : (context) => GuestLoginViewModel(),
            builder: (context, child) => Scaffold(
                body: CustomScrollView(
                    physics: PageScrollPhysics(),
                    slivers: [
                        FlexibleAppBar(title: AppLocalizations.of(context)!.guest_login_title),
                        SliverToBoxAdapter(
                            child: Column(
                                children: [
                                    TextField(
                                        autofocus: true,
                                        decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                            ),
                                            labelText: AppLocalizations.of(context)!.firstname_textfield_label,
                                            prefixIcon: Icon(Icons.person_outline),
                                            helperText: AppLocalizations.of(context)!.firstname_textfield_helper_text,
                                            helperMaxLines: 2,
                                        ),
                                        maxLength: 12,
                                        autofillHints: [AutofillHints.name],
                                        controller: context.read<GuestLoginViewModel>().firstnameController,
                                        textInputAction: TextInputAction.next,
                                        keyboardType: TextInputType.name,
                                        textCapitalization: TextCapitalization.sentences,
                                    ),
                                    SizedBox(height: 32),
                                    Material(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(24),
                                        child: Row(
                                            children: [
                                                Checkbox(value: context.watch<GuestLoginViewModel>().isTermsAccepted, onChanged: (value) {
                                                    context.read<GuestLoginViewModel>().setTermsAccepted(value!);
                                                }),
                                                RichText(
                                                    text: TextSpan(
                                                    text: AppLocalizations.of(context)!.data_protection_info_text_1,
                                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                                    children: [
                                                        TextSpan(
                                                            text: AppLocalizations.of(context)!.data_protection_info_text_2,
                                                            style: TextStyle(
                                                                color: Theme.of(context).colorScheme.primary,
                                                                fontWeight: FontWeight.bold
                                                            ),
                                                            recognizer: TapGestureRecognizer()
                                                                ..onTap = () async {
                                                                    await launchUrlString(Runtime.privacyPolicyUrl, mode: LaunchMode.externalApplication);
                                                                }
                                                        ),
                                                        TextSpan(
                                                            text: AppLocalizations.of(context)!.data_protection_info_text_3,
                                                        ),
                                                    ]
                                                    )
                                                )
                                                .expanded(),
                                            ],
                                        )
                                        .paddingSymmetric(horizontal: 8, vertical: 16),
                                    ),
                                ],
                            )
                            .paddingAll(16),
                        ),
                        SliverFillRemaining(
                            hasScrollBody: false,
                            child: FilledButton(
                                onPressed: context.watch<GuestLoginViewModel>().isTermsAccepted && context.watch<GuestLoginViewModel>().firstnameController.text.trim().isNotEmpty ? () => _handleLogin(context) : null,
                                child: Text(AppLocalizations.of(context)!.continue_button),
                            )
                            .align(Alignment.bottomRight)
                            .safeArea()
                            .paddingAll(16),
                        ),
                    ],
                ),
            )
        );
    }

    /// Verarbeitet den Login-Vorgang für einen Gastbenutzer.
    Future<void> _handleLogin(BuildContext context) async
    {
        try
        {
            await showLoadingOverlay(context, context.read<GuestLoginViewModel>().createGuestUser);
            Navigator.pushNamedAndRemoveUntil(context, Routes.onboarding, (Route<dynamic> route) => false);
        }
        catch (e)
        {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(AppLocalizations.of(context)!.guest_login_error_message),
                )
            );
        }
    }
}