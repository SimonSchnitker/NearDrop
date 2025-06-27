import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:gal/gal.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:mime/mime.dart';
import 'package:near_drop/Runtime.dart';
import 'package:near_drop/help/presentation/ReceivedFilesLocationInfoView.dart';
import 'package:near_drop/nearby/presentation/pages/NearbyPage.dart';
import 'package:near_drop/settings/domain/Setting.dart';
import 'package:near_drop/settings/domain/SettingsController.dart';
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
import '../../core/domain/entity/Device.dart';
import '../../core/domain/enums/ErrorState.dart';
import '../../core/domain/enums/SuccessState.dart';
import '../../main.dart';
import 'event_args/ConnectionCreatedEventArgs.dart';

/// Steuert den Transportprozess zwischen Geräten.
class TransportController
{
    static final Setting _isFirstTimeReceivingFilesSetting = Setting("isFirstTimeReceivingFiles", bool);
    static const String FOLDER_NAME = Runtime.appName;
    static const int MIN_BYTES_FOR_DATA_VOLUME_WARNING = 20000000; // 20 MB
    static const int MAX_CONNECTING_TRIES = 3;
    Directory? filesDirectory;

    final SignalingController _signalingController;
    final TransportGateway _transportGateway;
    final SettingsController _settingsController;

    TransportController(this._signalingController, this._transportGateway, this._settingsController);

    /// Initialisiert den Zielordner, in den empfangene Dateien gespeichert werden sollen.
    Future<bool> initFilesDirectory() async
    {
        try
        {
            filesDirectory = await _getFilesDirectory();
            return filesDirectory != null;
        }
        catch (e)
        {
            dprint("Fehler beim Erstellen des Zielordners: $e");
            return false;
        }
    }

    /// Startet den Signalisierungsprozess und wartet auf eingehende Verbindungen.
    void startSignaling()
    {
        _signalingController.onConnectionCreated.stream.listen(_onConnectionCreated);
        _signalingController.startListening();
        dprint("Signalisierung gestartet.");
    }

    /// Wird aufgerufen, wenn sich ein Gerät mit uns verbunden hat.
    Future<void> _onConnectionCreated(ConnectionCreatedEventArgs args) async
    {
        Device device = args.device;
        Connection connection = args.connection;

        // Sendeanfrage empfangen
        SendRequestDTO? sendRequest;
        try
        {
            sendRequest = await _transportGateway.receiveRequest(args.connection.networkStream!);
        }
        on Exception catch (e)
        {
            dprint("Fehler beim Empfangen der Sendeanfrage: $e");
            await device.closeConnection(connection: connection);
            return;
        }

        if (sendRequest == null)
        {
            dprint("Ungültige Sendeanfrage empfangen.");
            await device.closeConnection(connection: connection);
            return;
        }

        // Je nach Typ der Sendeanfrage verarbeiten
        if (sendRequest is SendRequestFilesDTO)
        {
            await _handleReceiveFiles(sendRequest, connection, device);
        }
        // Hier können in Zukunft weitere Typen von Sendeanfragen verarbeitet werden (Text, Ordner, etc.)
        else
        {
            await device.closeConnection(connection: connection);
        }
    }

    /// Verarbeitet die eingehende Sendeanfrage.
    Future<void> _handleReceiveFiles(SendRequestFilesDTO sendRequest, Connection connection, Device device) async
    {
        // Wenn der Zielordner null ist, kann der Transport nicht fortgesetzt werden
        if (filesDirectory == null)
        {
            dprint("Zielordner ist null.");

            try
            {
                // Dem Sender mitteilen, dass der Transport nicht fortgesetzt werden kann
                await connection.networkStream!.writeString(SendRequestAnswer.error.name);
            }
            on Exception catch (e)
            {
                dprint("Fehler beim Senden der Antwort: $e");
            }

            await device.closeConnection(connection: connection);
            return;
        }

        // Dem Benutzer die Anfrage anzeigen
        SendRequestAnswer answer = await showSendRequestDialog(device, sendRequest.filesCount, sendRequest.totalSize, sendRequest.mimeTypeGroup);

        // Wenn der Datenkanal mittlerweile geschlossen wurde, beenden
        if (connection.dataChannel?.state != RTCDataChannelState.RTCDataChannelOpen)
        {
            await device.closeConnection(connection: connection, errorState: ErrorState.error);
            return;
        }

        // Antwort senden
        try
        {
            await connection.networkStream!.writeString(answer.name);
        }
        on Exception catch (e)
        {
            dprint("Fehler beim Senden der Antwort: $e");
            await device.closeConnection(connection: connection, errorState: ErrorState.error);
            return;
        }

        // Wenn der Benutzer die Anfrage nicht akzeptiert hat, Verbindung schließen
        if (answer != SendRequestAnswer.accepted)
        {
            await device.closeConnection(connection: connection);
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
                dprint("Fehler beim Empfangen der Datei.");
                await device.closeConnection(connection: connection, errorState: ErrorState.error);
                await _deleteReceivedFile(receivedFile);
                await _deleteAllReceivedFiles(receivedFiles); // Alle vorherigen Dateien löschen
                return;
            }

            if (result == FileReceiveResult.ok)
            {
                dprint("Datei empfangen: ${receivedFile.name}");
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
                        dprint("Fehler beim Speichern der Datei in der Galerie: $e");
                    }
                }
            }
            else if (result == FileReceiveResult.userCanceled)
            {
                device.communicationInfo.onCanceledCompleted.add(connection.connectionId); // Mitteilen, dass das Bearbeiten des Abbruchs abgeschlossen ist (Wird im TransportViewModel benötigt)
                await device.closeConnection(connection: connection, errorState: ErrorState.userCanceled);
                await _deleteReceivedFile(receivedFile); // Aktuelle Datei löschen
                await _deleteAllReceivedFiles(receivedFiles); // Alle vorherigen Dateien löschen
                return;
            }
            else if (result == FileReceiveResult.skipped)
            {
                dprint("Datei wurde übersprungen: ${receivedFile.name}");
            }
            else
            {
                dprint("Fehler beim Empfangen der Datei.");
                await device.closeConnection(connection: connection, errorState: ErrorState.error);
                await _deleteReceivedFile(receivedFile);
                await _deleteAllReceivedFiles(receivedFiles); // Alle vorherigen Dateien löschen
                return;
            }
        }

        await device.closeConnection(connection: connection, successState: SuccessState.receivedSuccessfully);
        if (receivedFiles.isEmpty)
        {
            return;
        }

        // Empfangene Dateien auf der UI anzeigen
        await showImagePreviewDialog(context: NearbyPage.scaffoldKey.currentContext!, allFiles: receivedFiles, device: device, targetDirectory: filesDirectory, mimeTypeGroup: sendRequest.mimeTypeGroup);

        // BottomSheet mit Erklärung anzeigen, wenn Dateien auf diesem Gerät zum allerersten Mal empfangen wurden
        bool? isFirstTimeReceivingFiles = await _settingsController.get(_isFirstTimeReceivingFilesSetting);
        if (isFirstTimeReceivingFiles == null)
        {
            await _settingsController.set(_isFirstTimeReceivingFilesSetting, true); // Merken, dass Dateien empfangen wurden
            await showModalBottomSheet(
                context: NearbyPage.scaffoldKey.currentContext!,
                builder: (_) => ReceivedFilesLocationInfoView(),
                showDragHandle: true
            );
        }
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
            dprint("Fehler beim Schließen der Datei: $e");
        }

        try
        {
            await File(file.path).delete();
        }
        catch (e)
        {
            dprint("Fehler beim Löschen der Datei: $e");
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
        // Aktuelle Verbindung zum Gerät schließen, falls vorhanden
        await device.closeCurrentConnection();

        device.communicationInfo.setConnecting();

        // Gesamtgröße der Dateien berechnen und MimeTypeGroup bestimmen
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
            dprint("Zugriff auf Datei nicht möglich: $e");
            device.communicationInfo.setErrorState(ErrorState.error);
            return SendResponse.fileAccessError;
        }

        // Wenn das Gerät keine WLAN- oder Ethernet-Verbindung hat und die Gesamtgröße einen bestimmten Wert übersteigt, Datenvolumen-Warnung anzeigen
        List<ConnectivityResult> connectivity = await Connectivity().checkConnectivity();
        if (!connectivity.contains(ConnectivityResult.wifi) && !connectivity.contains(ConnectivityResult.ethernet) && totalSize >= MIN_BYTES_FOR_DATA_VOLUME_WARNING)
        {
            bool send = await showVolumeDataWarningDialog(totalSize);
            if (!send)
            {
                device.communicationInfo.setErrorState(ErrorState.userCanceled);
                return SendResponse.userCanceled;
            }
        }

        // Verbindung zum Gerät herstellen
        Connection? connection;
        for (int i = 1; i <= MAX_CONNECTING_TRIES; i++)
        {
            try
            {
                connection = await _signalingController.connect(device, i);
            }
            on Exception catch (e)
            {
                dprint("Verbindungsaufbau zu ${device.firstname} fehlgeschlagen: $e");
                device.communicationInfo.setErrorState(ErrorState.error);
                return SendResponse.connectionError;
            }

            // Prüfen, ob der Benutzer das Abbrechen angefordert hat
            if (device.communicationInfo.cancelationRequested)
            {
                device.communicationInfo.setErrorState(ErrorState.userCanceled);
                return SendResponse.userCanceled;
            }

            if (connection == null)
            {
                dprint("Verbindungsaufbau zu ${device.firstname} fehlgeschlagen. Versuch $i von $MAX_CONNECTING_TRIES.");
            }
            else
            {
                dprint("Verbindung zu ${device.firstname} erfolgreich hergestellt.");
                device.communicationInfo.connection = connection;
                break;
            }
        }

        // Wenn nach den maximalen Versuchen keine Verbindung hergestellt werden konnte, wird der Vorgang abgebrochen
        if (connection == null)
        {
            print("Verbindungsaufbau zu ${device.firstname} fehlgeschlagen.");
            device.communicationInfo.setErrorState(ErrorState.error);
            return SendResponse.timeout;
        }

        // Sendeanfrage senden
        device.communicationInfo.setRequesting();
        SendRequestAnswer answer;
        try
        {
            answer = await _transportGateway.request(connection.networkStream!, files.length, totalSize, mimeTypeGroup);
        }
        on Exception catch (e)
        {
            print("Fehler beim Senden der Anfrage: $e");
            await device.closeConnection(connection: connection, errorState: ErrorState.error);
            return SendResponse.connectionError;
        }

        // Antwort des Empfängers auswerten
        if (answer == SendRequestAnswer.declined)
        {
            await device.closeConnection(connection: connection, errorState: ErrorState.receiverDeclined);
            return SendResponse.receiverDeclined;
        }
        else if (answer == SendRequestAnswer.error)
        {
            await device.closeConnection(connection: connection, errorState: ErrorState.error);
            return SendResponse.receiverError;
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
                await device.closeConnection(connection: connection, errorState: ErrorState.error);
                return SendResponse.connectionError;
            }

            if (sendResult == FileSendResult.fileReadError)
            {
                // Dem Benutzer mit einem Dialog fragen, ob die Datei übersprungen werden soll
                bool skip = await showAskSkipFileDialog(file);
                if (skip)
                {
                    int length = await file.length();
                    bool response = false;
                    try
                    {
                        response = await _transportGateway.sendFileSkip(device, connection.networkStream!, length, progress);
                    }
                    catch (e)
                    {
                        print("Fehler beim Senden der FileSkip-Info: $e");
                        await device.closeConnection(connection: connection, errorState: ErrorState.error);
                        return SendResponse.connectionError;
                    }

                    if (!response)
                    {
                        print("Der Empfänger hat ein ungültiges Flag gesendet.");
                        await device.closeConnection(connection: connection, errorState: ErrorState.error);
                        return SendResponse.receiverError;
                    }
                }
                else
                {
                    print("Sender möchte den Transport abbrechen.");
                    try
                    {
                        await _transportGateway.sendCancelFlag(connection.networkStream!);
                    }
                    catch (e)
                    {
                        print("Fehler beim Senden des Abbruch-Flags: $e");
                    }

                    await device.closeConnection(connection: connection, errorState: ErrorState.userCanceled);
                    return SendResponse.userCanceled;
                }
            }
            else if (sendResult == FileSendResult.userCanceled)
            {
                print("Benutzer hat den Transport abgebrochen.");
                await device.closeConnection(connection: connection, errorState: ErrorState.userCanceled);
                device.communicationInfo.onCanceledCompleted.add(connection.connectionId); // Mitteilen, dass das Bearbeiten des Abbruchs abgeschlossen ist (Wird im TransportViewModel benötigt)
                return SendResponse.userCanceled;
            }
            else if (sendResult == FileSendResult.wrongFlagOrParameter)
            {
                print("Der Empfänger hat ein ungültiges Flag oder Parameter gesendet.");
                await device.closeConnection(connection: connection, errorState: ErrorState.error);
                return SendResponse.receiverError;
            }
        }

        await device.closeConnection(connection: connection, successState: SuccessState.sendedSuccessfully);
        return SendResponse.ok;
    }
}