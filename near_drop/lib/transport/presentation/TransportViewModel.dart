import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/Runtime.dart';
import 'package:near_drop/transport/domain/enums/SendResponse.dart';
import '../../core/domain/entity/Device.dart';
import '../../core/domain/enums/CommunicationState.dart';
import '../../core/domain/enums/ErrorState.dart';
import '../../main.dart';
import '../../settings/domain/Setting.dart';
import '../../settings/domain/SettingsController.dart';
import '../domain/TransportController.dart';
import '../domain/models/Connection.dart';

/// Steuert die UI des Dateiübertragungsprozesses.
class TransportViewModel extends ChangeNotifier
{
    static final Setting _sentCountSetting = Setting("sentCount", int);
    static const List<int> _sendCountsForReview = [5, 15, 30];
    static final _cancelTimeout = Duration(seconds: 8);

    final _transportController = KiwiContainer().resolve<TransportController>();
    final _settingsController = KiwiContainer().resolve<SettingsController>();
    bool isFilesDirectoryInitialized = true;

    final Setting _filesSentSetting = Setting("filesSent", bool);
    bool hasFilesSent = true;

    TransportViewModel()
    {
        _initFilesDirectory();
        _checkHasFilesSent();
    }

    /// Initialisiert den Ordner, in dem empfangene Dateien gespeichert werden.
    Future<void> _initFilesDirectory() async
    {
        isFilesDirectoryInitialized = await _transportController.initFilesDirectory();
        dprint("TransportViewModel: _initFilesDirectory: isFilesDirectoryInitialized: $isFilesDirectoryInitialized");
        notifyListeners();
    }

    /// Prüft, ob der Benutzer mindestens einmal Dateien gesendet hat.
    Future<void> _checkHasFilesSent() async
    {
        hasFilesSent = await _settingsController.get(_filesSentSetting) ?? false;
        dprint("TransportViewModel: _checkHasFilesSent: hasFilesSent: $hasFilesSent");
        notifyListeners();
    }

    /// Sendet Dateien an ein Gerät.
    Future<SendResponse> sendFiles(Device device, List<File> files) async
    {
        SendResponse response = await _transportController.sendFiles(device, files);

        try
        {
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
        }
        catch (e)
        {
            // Ignorieren, da es nicht kritisch ist
        }

        return response;
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

    /// Bricht die Übertragung ab.
    Future<void> cancelTransport(Device device) async
    {
        Connection? connection = device.communicationInfo.connection;
        if (connection == null)
        {
            device.communicationInfo.reset(); // Den Kommunikationsstatus zurücksetzen, da scheinbar etwas schiefgelaufen ist.
            return;
        }

        // Wenn der Status in "Anfragen" ist, wird die sofort abgebrochen, da kein Prozess intern nach dem cacelingRequested-Flag lauscht.
        if (device.communicationInfo.communicationState == CommunicationState.requesting)
        {
            await device.closeConnection(connection: connection, errorState: ErrorState.userCanceled);
            return;
        }
        // Im Status "Verbinden" wird der connectingCompleter abgeschlossen, um den Verbindungsprozess zu beenden.
        else if (device.communicationInfo.communicationState == CommunicationState.connecting)
        {
            device.communicationInfo.setCanceling();
            device.communicationInfo.connectingCompleter.complete(null);
        }
        // In allen anderen Zuständen wird das Flag gesetzt. Interne Methoden prüfen dieses Flag regelmäßig.
        // Ein Timeout wird eingestellt, sollte das Abbrechen "feststecken".
        else
        {
            // Am Event "onCanceledCompleted" wird gewartet, um zu prüfen, ob das Abbrechen erfolgreich war.
            // Eine interne Methode wird dieses Event auslösen, wenn das Abbrechen abgeschlossen ist.
            device.communicationInfo.onCanceledCompleted.stream.first.timeout(_cancelTimeout, onTimeout: () async
            {
                // Dieser Bereich wird aufgerufen, wenn das Abbrechen nicht innerhalb des Timeouts abgeschlossen wurde.
                // Prüfen, ob die Verbindung mittlerweile noch aktuell ist
                if (device.communicationInfo.connection?.connectionId == connection.connectionId)
                {
                    await device.closeConnection(connection: connection, errorState: ErrorState.userCanceled);
                }

                return 0;
            });

            // Abbrechen einleiten
            device.communicationInfo.setCanceling();
        }
    }
}