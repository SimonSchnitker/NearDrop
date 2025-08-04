import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/auth/domain/AuthController.dart';
import 'package:near_drop/settings/domain/SettingsController.dart';
import '../../../Runtime.dart';
import '../../../settings/domain/Setting.dart';

/// Interaktionslogik der GuestSettingsPage.
class GuestSettingsViewModel extends ChangeNotifier
{
    static final firstnameSetting = Setting("firstname", String);
    final SettingsController _settingsController = KiwiContainer().resolve<SettingsController>();
    final AuthController _authController = KiwiContainer().resolve<AuthController>();

    String firstname = Runtime.firstname;
    final TextEditingController firstnameController = TextEditingController();

    Future<void> updateFirstname() async
    {
        if (firstnameController.text.trim().isEmpty)
        {
            return;
        }

        firstnameController.text = firstnameController.text.trim();
        await _settingsController.set(firstnameSetting, firstnameController.text);

        firstname = firstnameController.text;
        Runtime.firstname = firstname;
        Runtime.onFirstnameChanged.add(firstname);
        notifyListeners();
    }

    Future<void> deleteAccount() async
    {
        await _authController.signOutAndDeleteAccount();
    }
}