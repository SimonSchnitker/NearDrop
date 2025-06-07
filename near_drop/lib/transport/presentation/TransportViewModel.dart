import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/transport/domain/enums/SendResponse.dart';
import '../../core/domain/entity/Device.dart';
import '../../core/domain/enums/CommunicationState.dart';
import '../../core/domain/enums/ErrorState.dart';
import '../domain/TransportController.dart';
import '../domain/models/Connection.dart';

/// Steuert die UI des Dateiübertragungsprozesses.
class TransportViewModel extends ChangeNotifier
{
    final _transportController = KiwiContainer().resolve<TransportController>();
    static final _cancelTimeout = Duration(seconds: 8);
    bool isFilesDirectoryInitialized = false;

    TransportViewModel()
    {
        isFilesDirectoryInitialized = _transportController.filesDirectory != null;
        print("TransportViewModel: isFilesDirectoryInitialized: $isFilesDirectoryInitialized");
    }

    /// Sendet Dateien an ein Gerät.
    Future<SendResponse> sendFiles(Device device, List<File> files) async
    {
        return await _transportController.sendFiles(device, files);
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
        // Im Status "Verbinden" reicht es das Flag zu setzen, da das Verbinden nicht direkt abgebrochen werden sollte.
        // Das Verbinden stopp nämlich in jedem Fall nach einiger Zeit.
        else if (device.communicationInfo.communicationState == CommunicationState.connecting)
        {
            device.communicationInfo.setCanceling();
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