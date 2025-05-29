import 'package:flutter/material.dart';
import 'package:near_drop/core/enums/ErrorState.dart';
import 'package:near_drop/core/enums/SuccessState.dart';
import '../enums/CommunicationState.dart';

/// Beschreibt den Kommunikationsstatus und den Fortschritt einer Kommunikation zu einem Gerät.
class CommunicationInfo extends ChangeNotifier
{
    CommunicationState communicationState = CommunicationState.none;
    SuccessState successState = SuccessState.none;
    ErrorState errorState = ErrorState.none;
    double? progress = 0.0;
    bool cancelationRequested = false;

    /// Setzt den Status auf "Standardzustand".
    void reset()
    {
        cancelationRequested = false;
        this.communicationState = CommunicationState.none;
        this.progress = 0.0;
        notifyListeners();
    }

    /// Setzt den Status auf "Verbinden".
    void setConnecting() async
    {
        this.communicationState = CommunicationState.connecting;
        this.progress = null;
        notifyListeners();
    }

    /// Setzt den Status auf "Anfragen".
    void setRequesting()
    {
        this.communicationState = CommunicationState.requesting;
        this.progress = null;
        notifyListeners();
    }

    /// Setzt den Status auf "Senden".
    void setSending(double progress)
    {
        this.communicationState = CommunicationState.sending;
        this.progress = progress;
        notifyListeners();
    }

    /// Setzt den Status auf "Empfangen".
    void setReceiving(double progress)
    {
        this.communicationState = CommunicationState.receiving;
        this.progress = progress;
        notifyListeners();
    }

    /// Setzt den Status auf "Abbrechen".
    void setCanceling()
    {
        this.cancelationRequested = true;
        this.communicationState = CommunicationState.canceling;
        this.progress = null;
        notifyListeners();
    }

    /// Setzt einen Erfolg-Status.
    Future<void> setSuccessState(SuccessState successState) async
    {
        this.cancelationRequested = false;
        this.communicationState = CommunicationState.none;
        this.progress = 0.0;
        this.successState = successState;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 3));
        this.successState = SuccessState.none;
        notifyListeners();
    }

    /// Setzt einen Fehler-Status.
    Future<void> setErrorState(ErrorState errorState) async
    {
        this.cancelationRequested = false;
        this.communicationState = CommunicationState.none;
        this.progress = 0.0;
        this.errorState = errorState;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 3));
        this.errorState = ErrorState.none;
        notifyListeners();
    }
}