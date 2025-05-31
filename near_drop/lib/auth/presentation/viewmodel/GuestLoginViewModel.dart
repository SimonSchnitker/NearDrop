import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/auth/domain/AuthController.dart';
import 'package:near_drop/nearby/domain/NearbyController.dart';
import 'package:near_drop/transport/domain/TransportController.dart';
import '../../../Runtime.dart';

/// Interaktionslogik der GuestLoginPage.
class GuestLoginViewModel extends ChangeNotifier
{
    final AuthController _authController = KiwiContainer().resolve<AuthController>();
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

        firstnameController.clear();
        isTermsAccepted = false;
    }
}