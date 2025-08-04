import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/auth/domain/AuthController.dart';
import 'package:near_drop/auth/domain/model/UserData.dart';

class SavedUserDataViewModel extends ChangeNotifier
{
    final AuthController _authController = KiwiContainer().resolve<AuthController>();
    UserData? userData;

    Future<void> getSavedUserData() async
    {
        this.userData = await _authController.getSavedUserData();
        notifyListeners();
    }
}