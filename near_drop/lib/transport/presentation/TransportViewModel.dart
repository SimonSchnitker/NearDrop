import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/core/domain/entity/Device.dart';
import 'package:near_drop/transport/domain/enums/SendResponse.dart';
import '../../main.dart';
import '../domain/TransportController.dart';

class TransportViewModel extends ChangeNotifier
{
    final _transportController = KiwiContainer().resolve<TransportController>();
    bool isFilesDirectoryInitialized = true;
    bool hasFilesSent = true;

    TransportViewModel()
    {
        _initFilesDirectory();
    }

    /// Initialisiert den Ordner, in dem empfangene Dateien gespeichert werden.
    Future<void> _initFilesDirectory() async
    {
        isFilesDirectoryInitialized = await _transportController.initFilesDirectory();
        dprint("TransportViewModel: _initFilesDirectory: isFilesDirectoryInitialized: $isFilesDirectoryInitialized");
        notifyListeners();
    }

    /// Sendet Dateien an ein Gerät.
    Future<SendResponse> sendFiles(Device device, List<File> files) async
    {
        return await _transportController.sendFiles(device, files);
    }

    /// Bricht den Transport von Dateien zu einem Gerät ab.
    Future<void> cancelTransport(Device device) async
    {
        await _transportController.cancelTransport(device);
    }
}