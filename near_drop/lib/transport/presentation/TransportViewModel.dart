import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/core/domain/entity/Device.dart';
import 'package:near_drop/transport/domain/enums/SendResponse.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../main.dart';
import '../../settings/domain/Setting.dart';
import '../../settings/domain/SettingsController.dart';
import '../domain/TransportController.dart';

class TransportViewModel extends ChangeNotifier
{
    final _transportController = KiwiContainer().resolve<TransportController>();
    final _settingsController = KiwiContainer().resolve<SettingsController>();

    bool isFilesDirectoryInitialized = true;
    bool hasFilesSent = true;
    final sharedFiles = <SharedMediaFile>[];

    final Setting _filesSentSetting = Setting("filesSent", bool);
    static final Setting _sentCountSetting = Setting("sentCount", int);
    static const List<int> _sendCountsForReview = [5, 10, 20];

    TransportViewModel()
    {
        _initFilesDirectory();
        _checkHasSharedFiles();
        _listenForMediaSharing();
    }

    /// Prüft, ob die App Dateien empfangen hat, die über die Teilen-Funktion des Betriebssystems gesendet wurden.
    Future<void> _checkHasSharedFiles() async
    {
        ReceiveSharingIntent.instance.getInitialMedia().then((value) {
            sharedFiles.clear();
            sharedFiles.addAll(value);
            ReceiveSharingIntent.instance.reset();
        });
    }

    /// Hört auf neue Medien, die über die Teilen-Funktion des Betriebssystems gesendet werden.
    Future<void> _listenForMediaSharing() async
    {
        ReceiveSharingIntent.instance.getMediaStream().listen((value) {
            sharedFiles.clear();
            sharedFiles.addAll(value);
            notifyListeners();
        }, onError: (err) {
            print("getIntentDataStream error: $err");
        });
    }

    void clearSharedFiles()
    {
        sharedFiles.clear();
        notifyListeners();
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
        SendResponse response = await _transportController.sendFiles(device, files);

        // Wenn Dateien das erste Mal erfolgreich gesendet wurden, wird das Flag in den Einstellungen auf true gesetzt.
        if (response == SendResponse.ok && !hasFilesSent)
        {
            await _settingsController.set(_filesSentSetting, true);
            hasFilesSent = true;
            notifyListeners();
        }

        // ggf. In-App-Bewertung anzeigen, wenn die Dateien erfolgreich gesendet wurden und der Benutzer noch nicht bewertet hat.
        if (response == SendResponse.ok)
        {
            _handleInAppReview(); // Kein await!
        }

        return response;
    }

    /// Bricht den Transport von Dateien zu einem Gerät ab.
    Future<void> cancelTransport(Device device) async
    {
        await _transportController.cancelTransport(device);
    }

    /// Verarbeitet das Anzeigen einer In-App-Bewertung, wenn der Benutzer Dateien gesendet hat.
    Future<void> _handleInAppReview() async
    {
        // Anzahl gesendeter Male abrufen und erhöhen
        int sentCount = await _settingsController.get(_sentCountSetting) ?? 0;
        sentCount++;
        await _settingsController.set(_sentCountSetting, sentCount);

        // Wenn die Anzahl der gesendeten Male in der Liste für Bewertungen enthalten ist und die In-App-Bewertung verfügbar ist, wird die Bewertung angefordert.
        if (_sendCountsForReview.contains(sentCount) && await InAppReview.instance.isAvailable())
        {
            await InAppReview.instance.requestReview();
        }
    }
}