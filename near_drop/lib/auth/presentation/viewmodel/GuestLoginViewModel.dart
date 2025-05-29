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
    final NearbyController _nearbyController = KiwiContainer().resolve<NearbyController>();
    final TransportController _transportController = KiwiContainer().resolve<TransportController>();
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
        await _authController.updateNearbyUuid();

        bool realtimeChannelInitialized = await Runtime.initializeChannel();
        if (!realtimeChannelInitialized)
        {
            await _authController.signOutAndDeleteAccount();
            throw Exception("RealtimeChannel konnte nicht initialisiert werden");
        }

        _nearbyController.startListeningForDeviceData();
        _transportController.startSignaling();

        firstnameController.clear();
        isTermsAccepted = false;
    }
}