import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/auth/domain/AuthController.dart';

class PrivacyUpdatedViewModel extends ChangeNotifier
{
    final AuthController _authController = KiwiContainer().resolve<AuthController>();

    Future<void> acceptNewPrivacyPolicy() async
    {
        await _authController.recordNewestPrivacyConsent();
    }

    Future<void> deleteAccount() async
    {
        await _authController.signOutAndDeleteAccount();
    }
}