import 'dart:io';
import 'package:near_drop/core/enums/ErrorState.dart';
import 'package:near_drop/transport/domain/SignalingController.dart';
import 'package:near_drop/transport/domain/enums/SendResponse.dart';
import 'package:near_drop/transport/domain/models/Connection.dart';
import '../../core/entity/Device.dart';

class TransportController
{
    final SignalingController _signalingController;

    TransportController(this._signalingController);

    void startSignalingListening()
    {
        _signalingController.startListening();
        print("Signalisierung gestartet");
    }

    /// Sendet Dateien an ein Gerät.
    Future<SendResponse> sendFiles(Device device, List<File> files) async
    {
        device.communicationInfo.setConnecting();

        // Gesamtgröße der Dateien berechnen
        int totalSize = 0;
        try
        {
            for (File file in files)
            {
                totalSize += await file.length();
            }
        }
        on FileSystemException catch (e)
        {
            print("Zugriff auf Datei nicht möglich: $e");
            return SendResponse.fileAccessError;
        }

        // Verbindung zum Gerät herstellen
        Connection? connection;
        try
        {
             connection = await _signalingController.connect(device);

            if (connection == null)
            {
                print("Verbindung zu ${device.firstname} fehlgeschlagen.");
                return SendResponse.timeout;
            }
        }
        on Exception catch (e)
        {
            print("Verbindung zu ${device.firstname} fehlgeschlagen: $e");
            return SendResponse.connectionError;
        }

        return SendResponse.ok;
    }
}