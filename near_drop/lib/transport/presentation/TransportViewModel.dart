import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/core/enums/CommunicationState.dart';
import 'package:near_drop/core/enums/ErrorState.dart';
import 'package:near_drop/core/enums/SuccessState.dart';
import 'package:near_drop/transport/domain/enums/SendResponse.dart';
import '../../core/entity/Device.dart';
import '../domain/TransportController.dart';

/// Steuert die UI des Dateiübertragungsprozesses.
class TransportViewModel extends ChangeNotifier
{
    final _transportController = KiwiContainer().resolve<TransportController>();
    bool _isInitialized = false;
    static final _cancelTimeout = Duration(seconds: 8);

    /// Initialisiert den Signalisierungsprozess.
    void initSignaling()
    {
        if (_isInitialized)
        {
            return;
        }

        _transportController.init();
        _isInitialized = true;
    }

    /// Sendet Dateien an ein Gerät.
    Future<SendResponse> sendFiles(Device device, List<File> files) async
    {
        SendResponse response = await _transportController.sendFiles(device, files);

        switch (response)
        {
            case SendResponse.ok:
                device.communicationInfo.setSuccessState(SuccessState.sendedSuccessfully);
                break;
            case SendResponse.receiverDeclined:
                device.communicationInfo.setErrorState(ErrorState.receiverDeclined);
                break;
            case SendResponse.userCanceled:
                device.communicationInfo.setErrorState(ErrorState.userCanceled);
                device.onCanceledCompleted.add(null); // Mitteilen, dass der Transport abgebrochen wurde
                break;
            default:
                device.communicationInfo.setErrorState(ErrorState.error);
        }

        device.clearConnection();
        return response;
    }

    /// Bricht die Übertragung ab.
    Future<void> cancelTransport(Device device) async
    {
        if (device.connection == null)
        {
            return;
        }

        // Wenn der Status in "Anfragen" ist, wird die sofort abgebrochen, da kein Prozess intern nach dem cacelingRequested-Flag lauscht.
        if (device.communicationInfo.communicationState == CommunicationState.requesting)
        {
            device.communicationInfo.setErrorState(ErrorState.userCanceled);
            await device.clearConnection();
            return;
        }

        // Im Status "Verbinden" reicht es das Flag zu setzen, da das Verbinden nicht direkt abgebrochen werden sollte.
        if (device.communicationInfo.communicationState == CommunicationState.connecting)
        {
            device.communicationInfo.setCanceling();
        }
        // In allen anderen Zuständen wird das Flag gesetzt und ein Timeout eingestellt, sollte das Abbrechen "feststecken"
        else
        {
            device.onCanceledCompleted.stream.first.timeout(_cancelTimeout, onTimeout: () {
                device.communicationInfo.setErrorState(ErrorState.userCanceled);
                device.clearConnection();
            });

            device.communicationInfo.setCanceling();
        }
    }
}