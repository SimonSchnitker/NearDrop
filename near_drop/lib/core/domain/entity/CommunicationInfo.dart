import 'dart:async';
import 'package:flutter/material.dart';
import 'package:near_drop/transport/domain/models/Connection.dart';
import '../enums/CommunicationState.dart';
import '../enums/ErrorState.dart';
import '../enums/SuccessState.dart';

/// Beschreibt den Kommunikationsstatus und den Fortschritt einer Kommunikation zu einem Gerät.
class CommunicationInfo extends ChangeNotifier
{
    Connection? connection;
    Completer connectingCompleter = Completer(); // Wird verwendet, damit von überall aus das Verbinden abgebrochen werden kann.
    CommunicationState communicationState = CommunicationState.none;
    SuccessState successState = SuccessState.none;
    ErrorState errorState = ErrorState.none;
    double? progress = 0.0;

    StreamController<int> onCanceledCompleted = StreamController<int>.broadcast();

    /// Schließt die aktuelle Verbindung.
    Future<void> closeConnection() async
    {
        await connection?.close();
        connection = null;
    }

    /// Setzt den Status auf "Standardzustand".
    void reset()
    {
        this.communicationState = CommunicationState.none;
        this.progress = 0.0;
        notifyListeners();
    }

    /// Setzt den Status auf "Verbinden".
    void setConnecting() async
    {
        if (communicationState == CommunicationState.canceling) return;

        this.communicationState = CommunicationState.connecting;
        this.progress = null;
        notifyListeners();
    }

    /// Setzt den Status auf "Anfragen".
    void setRequesting()
    {
        if (communicationState == CommunicationState.canceling) return;

        this.communicationState = CommunicationState.requesting;
        this.progress = null;
        notifyListeners();
    }

    /// Setzt den Status auf "Senden".
    void setSending(double progress)
    {
        if (communicationState == CommunicationState.canceling) return;

        this.communicationState = CommunicationState.sending;
        this.progress = progress;
        notifyListeners();
    }

    /// Setzt den Status auf "Empfangen".
    void setReceiving(double progress)
    {
        if (communicationState == CommunicationState.canceling) return;

        this.communicationState = CommunicationState.receiving;
        this.progress = progress;
        notifyListeners();
    }

    /// Setzt den Status auf "Abbrechen".
    void setCanceling()
    {
        this.communicationState = CommunicationState.canceling;
        this.progress = null;
        notifyListeners();
    }

    /// Setzt einen Erfolg-Status.
    Future<void> setSuccessState(SuccessState successState) async
    {
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
        this.communicationState = CommunicationState.none;
        this.progress = 0.0;
        this.errorState = errorState;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 3));
        this.errorState = ErrorState.none;
        notifyListeners();
    }
}