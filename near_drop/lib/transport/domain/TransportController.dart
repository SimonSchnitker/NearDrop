import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:gal/gal.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:mime/mime.dart';
import 'package:near_drop/core/enums/ErrorState.dart';
import 'package:near_drop/core/enums/SuccessState.dart';
import 'package:near_drop/nearby/presentation/pages/NearbyPage.dart';
import 'package:near_drop/transport/data/TransportGateway.dart';
import 'package:near_drop/transport/domain/SignalingController.dart';
import 'package:near_drop/transport/domain/TransportDialogs.dart';
import 'package:near_drop/transport/domain/enums/FileReceiveResult.dart';
import 'package:near_drop/transport/domain/enums/FileSendResult.dart';
import 'package:near_drop/transport/domain/enums/MimeTypeGroup.dart';
import 'package:near_drop/transport/domain/enums/SendRequestAnswer.dart';
import 'package:near_drop/transport/domain/enums/SendResponse.dart';
import 'package:near_drop/transport/domain/models/Connection.dart';
import 'package:near_drop/transport/domain/models/Progress.dart';
import 'package:near_drop/transport/data/dto/SendRequestDTO.dart';
import 'package:near_drop/transport/data/dto/SendRequestFilesDTO.dart';
import 'package:near_drop/transport/domain/models/ReceivedFile.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/entity/Device.dart';
import 'event_args/ConnectionCreatedEventArgs.dart';

/// Steuert den Transportprozess zwischen Geräten.
class TransportController
{
    static const String FOLDER_NAME = "Near Drop";
    static const int MIN_BYTES_FOR_DATA_VOLUME_WARNING = 20000000; // 20 MB
    Directory? filesDirectory;

    final SignalingController _signalingController;
    final TransportGateway _transportGateway;

    TransportController(this._signalingController, this._transportGateway)
    {
        initFilesDirectory();
    }

    /// Initialisiert den Zielordner, in den empfangene Dateien gespeichert werden sollen.
    Future<void> initFilesDirectory() async
    {
        try
        {
            filesDirectory = await _getFilesDirectory();
        }
        catch (e)
        {
            print("Fehler beim Erstellen des Zielordners: $e");
        }
    }

    /// Startet den Signalisierungsprozess und wartet auf eingehende Verbindungen.
    void startSignaling()
    {
        _signalingController.onConnectionCreated.stream.listen(_onConnectionCreated);
        _signalingController.startListening();
        print("Signalisierung gestartet.");
    }

    /// Wird aufgerufen, wenn sich ein Gerät mit uns verbunden hat.
    Future<void> _onConnectionCreated(ConnectionCreatedEventArgs args) async
    {
        // Sendeanfrage empfangen
        SendRequestDTO? sendRequest;
        try
        {
            sendRequest = await _transportGateway.receiveRequest(args.connection.networkStream!);
        }
        on Exception catch (e)
        {
            print("Fehler beim Empfangen der Sendeanfrage: $e");
            await args.device.clearConnection();
            return;
        }

        if (sendRequest == null)
        {
            print("Ungültige Sendeanfrage empfangen.");
            await args.device.clearConnection();
            return;
        }

        // Je nach Typ der Sendeanfrage verarbeiten
        if (sendRequest is SendRequestFilesDTO)
        {
            await _handleReceiveFiles(sendRequest, args.connection, args.device);
        }
        else
        {
            await args.device.clearConnection();
        }
    }

    /// Verarbeitet die eingehende Sendeanfrage.
    Future<void> _handleReceiveFiles(SendRequestFilesDTO sendRequest, Connection connection, Device device) async
    {
        // Wenn der Zielordner null ist, kann der Transport nicht fortgesetzt werden
        if (filesDirectory == null)
        {
            print("Zielordner ist null.");

            try
            {
                // Dem Sender mitteilen, dass der Transport nicht fortgesetzt werden kann
                await connection.networkStream!.writeString(SendRequestAnswer.error.name);
            }
            on Exception catch (e)
            {
                print("Fehler beim Senden der Antwort: $e");
            }

            await device.clearConnection();
            return;
        }

        // Dem Benutzer die Anfrage anzeigen
        print("Sendeanfrage-Dialog wird angezeigt");
        SendRequestAnswer answer = await showSendRequestDialog(device, sendRequest.filesCount, sendRequest.totalSize, sendRequest.mimeTypeGroup);

        // Wenn der Datenkanal mittlerweile geschlossen wurde, beenden
        if (connection.dataChannel?.state != RTCDataChannelState.RTCDataChannelOpen)
        {
            return;
        }

        // Antwort senden
        try
        {
            await connection.networkStream!.writeString(answer.name);
        }
        on Exception catch (e)
        {
            print("Fehler beim Senden der Antwort: $e");
            device.communicationInfo.setErrorState(ErrorState.error);
            await device.clearConnection();
            return;
        }

        // Wenn der Benutzer die Anfrage nicht akzeptiert hat, Verbindung schließen
        if (answer != SendRequestAnswer.accepted)
        {
            await device.clearConnection();
            return;
        }

        // Dateien empfangen
        device.communicationInfo.setReceiving(0);
        Progress progress = Progress(sendRequest.totalSize);
        List<ReceivedFile> receivedFiles = [];
        for (int i = 0; i < sendRequest.filesCount; i++)
        {
            final receivedFile = ReceivedFile(); // Hier werden die Dateiinformationen der Datei hineingeschrieben
            FileReceiveResult result;
            try
            {
                result = await _transportGateway.receiveFile(device, connection.networkStream!, progress, filesDirectory!, receivedFile);
            }
            catch (e)
            {
                print("Fehler beim Empfangen der Datei.");
                await _deleteReceivedFile(receivedFile);

                // TODO: Dialog anzeigen, dass die Datei nicht empfangen werden konnte
                continue;
            }

            if (result == FileReceiveResult.ok)
            {
                print("Datei empfangen: ${receivedFile.name}");
                receivedFiles.add(receivedFile);

                // Wenn die Datei ein Bild oder Video ist, soll es in der Galerie angezeigt werden
                if (receivedFile.mimeType.startsWith("image/") || receivedFile.mimeType.startsWith("video/"))
                {
                    try
                    {
                        await _putMediaToGallery(receivedFile);
                    }
                    catch (e)
                    {
                        print("Fehler beim Speichern der Datei in der Galerie: $e");
                    }
                }
            }
            else if (result == FileReceiveResult.userCanceled)
            {
                device.onCanceledCompleted.add(null); // Mitteilen, dass der Transport abgebrochen wurde
                device.communicationInfo.setErrorState(ErrorState.userCanceled);
                await device.clearConnection();
                await _deleteReceivedFile(receivedFile); // Aktuelle Datei löschen
                await _deleteAllReceivedFiles(receivedFiles); // Alle vorherigen Dateien löschen
                return;
            }
            else
            {
                print("Fehler beim Empfangen der Datei.");
                await _deleteReceivedFile(receivedFile);

                // TODO: Dialog anzeigen, dass die Datei nicht empfangen werden konnte
            }
        }

        device.communicationInfo.setSuccessState(SuccessState.receivedSuccessfully);
        device.clearConnection();

        // Empfangene Dateien auf der UI anzeigen
        await showImagePreviewDialog(context: NearbyPage.scaffoldKey.currentContext!, allFiles: receivedFiles, device: device, targetDirectory: filesDirectory, mimeTypeGroup: sendRequest.mimeTypeGroup);
    }

    /// Kümmert sich darum, dass eine Mediendatei unter Android und iOS in der Gallerie auftaucht.
    Future<void> _putMediaToGallery(ReceivedFile file) async
    {
        if (Platform.isAndroid)
        {
            await MediaScanner.loadMedia(path: file.path);
        }
        else if (Platform.isIOS)
        {
            if (await Gal.requestAccess(toAlbum: true))
            {
                if (file.mimeType.startsWith("image/"))
                {
                    await Gal.putImage(file.path, album: FOLDER_NAME);
                }
                else if (file.mimeType.startsWith("video/"))
                {
                    await Gal.putVideo(file.path, album: FOLDER_NAME);
                }
            }
        }
    }

    /// Löscht eine empfangene Datei.
    /// Dies ist notwendig, falls es beim Empfang der Datei zu einem Fehler kommt.
    Future<void> _deleteReceivedFile(ReceivedFile file) async
    {
        try
        {
            // Vorsichthalbar die Datei schließen, falls sie noch geöffnet ist
            if (!file.fullyReceived)
            {
                await file.raf?.close();
            }
        }
        on Exception catch (e)
        {
            print("Fehler beim Schließen der Datei: $e");
        }

        try
        {
            await File(file.path).delete();
        }
        catch (e)
        {
            print("Fehler beim Löschen der Datei: $e");
        }
    }

    /// Löscht empfangene Dateien.
    /// Dies ist notwendig, falls es beim Empfangen zu einem Fehler kommt.
    Future<void> _deleteAllReceivedFiles(List<ReceivedFile> files) async
    {
        for (ReceivedFile file in files)
        {
            await _deleteReceivedFile(file);
        }
    }

    /// Gibt den Ordner zurück, in den empfangene Dateien gespeichert werden soll.
    Future<Directory?> _getFilesDirectory() async
    {
        Directory? targetDirectory;

        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
        {
            targetDirectory = await getDownloadsDirectory();
        }
        else if (Platform.isAndroid)
        {
            // Öffentlicher Download-Ordner
            String path = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOAD);
            targetDirectory = Directory(join(path, FOLDER_NAME));
        }
        else if (Platform.isIOS)
        {
            return getApplicationDocumentsDirectory();
        }

        if (targetDirectory == null)
        {
            return null;
        }

        if (await targetDirectory.exists() == false)
        {
            return await targetDirectory.create(recursive: true);
        }

        return targetDirectory;
    }



    /// Bestimmt die Gruppe der MIME-Typen basierend auf den übergebenen Dateien.
    MimeTypeGroup _getMimeTypeGroup(List<File> files)
    {
        List<String> mimeTypes = [];
        for (File file in files)
        {
            String mimeType = lookupMimeType(file.path) ?? "";
            mimeTypes.add(mimeType);
        }

        if (mimeTypes.every((element) => element.startsWith("image/")))
        {
            return MimeTypeGroup.images;
        }
        else if (mimeTypes.every((element) => element.startsWith("video/")))
        {
            return MimeTypeGroup.videos;
        }
        else if (mimeTypes.every((element) => element.startsWith("audio/")))
        {
            return MimeTypeGroup.audios;
        }
        else if (mimeTypes.every((element) => element.startsWith("image/") || element.startsWith("video/") || element.startsWith("audio/")))
        {
            return MimeTypeGroup.media;
        }

        return MimeTypeGroup.mixed;
    }

    /// Sendet Dateien an ein Gerät.
    Future<SendResponse> sendFiles(Device device, List<File> files) async
    {
        device.communicationInfo.setConnecting();

        // Gesamtgröße der Dateien berechnen
        int totalSize = 0;
        MimeTypeGroup mimeTypeGroup = MimeTypeGroup.mixed;
        try
        {
            for (File file in files)
            {
                totalSize += await file.length();
            }

            mimeTypeGroup = _getMimeTypeGroup(files);
        }
        on FileSystemException catch (e)
        {
            print("Zugriff auf Datei nicht möglich: $e");
            return SendResponse.fileAccessError;
        }

        // Wenn das Gerät keine WLAN- oder Ethernet-Verbindung hat und die Gesamtgröße einen bestimmten Wert übersteigt, Datenvolumen-Warnung anzeigen
        List<ConnectivityResult> connectivity = await Connectivity().checkConnectivity();
        if (!connectivity.contains(ConnectivityResult.wifi) && !connectivity.contains(ConnectivityResult.ethernet) && totalSize >= MIN_BYTES_FOR_DATA_VOLUME_WARNING)
        {
            bool send = await showVolumeDataWarningDialog(totalSize);
            if (!send)
            {
                return SendResponse.userCanceled;
            }
        }

        // Verbindung zum Gerät herstellen
        Connection? connection;
        try
        {
             connection = await _signalingController.connect(device);

             // Prüfen, ob der Benutzer das Abbrechen angefordert hat
             if (device.communicationInfo.cancelationRequested)
             {
                 return SendResponse.userCanceled;
             }

            if (connection == null)
            {
                print("Verbindung zu ${device.firstname} fehlgeschlagen.");
                return SendResponse.timeout;
            }
        }
        on Exception catch (e)
        {
            print("Verbindung zu ${device.firstname} fehlgeschlagen: $e");

            // Prüfen, ob der Benutzer das Abbrechen angefordert hat
            if (device.communicationInfo.cancelationRequested)
            {
                return SendResponse.userCanceled;
            }

            return SendResponse.connectionError;
        }

        // Sendeanfrage senden
        device.communicationInfo.setRequesting();
        SendRequestAnswer answer;
        try
        {
            answer = await _transportGateway.request(connection.networkStream!, files.length, totalSize, mimeTypeGroup);

            if (answer == SendRequestAnswer.declined)
            {
                return SendResponse.receiverDeclined;
            }
            else if (answer == SendRequestAnswer.error)
            {
                return SendResponse.receiverError;
            }
        }
        on Exception catch (e)
        {
            print("Fehler beim Senden der Anfrage: $e");
            return SendResponse.connectionError;
        }

        // Dateien senden
        device.communicationInfo.setSending(0);
        Progress progress = Progress(totalSize);
        for (File file in files)
        {
            FileSendResult sendResult;
            try
            {
                sendResult = await _transportGateway.sendFile(device, connection.networkStream!, file, progress);
            }
            on Exception catch (e)
            {
                print("Fehler beim Senden der Datei: $e");
                return SendResponse.connectionError;
            }

            if (sendResult == FileSendResult.fileReadError)
            {
                // Todo: Dialog anzeigen, dass die Datei nicht gesendet werden konnte
                int length = await file.length();
                bool response;
                try
                {
                     response = await _transportGateway.sendFileSkip(connection.networkStream!, length);
                }
                catch (e)
                {
                    print("Zugriff auf Datei nicht möglich: $e");
                    return SendResponse.connectionError;
                }

                if (!response)
                {
                    print("Fehler beim Überspringen der Datei.");
                    return SendResponse.receiverError;
                }
            }
            else if (sendResult == FileSendResult.userCanceled)
            {
                print("Benutzer hat den Transport abgebrochen.");
                return SendResponse.userCanceled;
            }
            else if (sendResult == FileSendResult.error)
            {
                print("Fehler beim Senden der Datei.");
                return SendResponse.receiverError;
            }
        }

        return SendResponse.ok;
    }
}