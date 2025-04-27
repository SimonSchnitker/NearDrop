import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/auth/domain/AuthController.dart';
import 'package:near_drop/device/domain/DeviceController.dart';

/// Interaktionslogik der GuestLoginPage.
class GuestLoginViewModel extends ChangeNotifier
{
    final AuthController _authController = KiwiContainer().resolve<AuthController>();
    final DeviceController _deviceController = KiwiContainer().resolve<DeviceController>();
    final TextEditingController firstnameController = TextEditingController();
    bool isTermsAccepted = false;

    GuestLoginViewModel()
    {
        firstnameController.addListener(() {
            notifyListeners();
        });
    }

    void setTermsAccepted(bool isChecked)
    {
        isTermsAccepted = isChecked;
        notifyListeners();
    }

    Future<void> createGuestUser() async
    {
        await _authController.signInAnonymous(firstnameController.text);
        await _deviceController.updateNearbyUuid();
        firstnameController.clear();
        isTermsAccepted = false;
    }
}