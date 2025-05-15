import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
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

        if (response == SendResponse.ok)
        {
            device.communicationInfo.setSuccessState(SuccessState.sendedSuccessfully);
        }
        else if (response == SendResponse.receiverDeclined)
        {
            device.communicationInfo.setErrorState(ErrorState.receiverDeclined);
        }
        else
        {
            device.communicationInfo.setErrorState(ErrorState.error);
        }

        device.communicationInfo.reset();
        device.connection?.close();
        device.connection = null;
        return response;
    }
}