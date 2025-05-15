import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:near_drop/core/enums/ErrorState.dart';
import 'package:near_drop/core/enums/SuccessState.dart';
import 'package:near_drop/nearby/presentation/pages/NearbyPage.dart';
import 'package:near_drop/transport/data/TransportGateway.dart';
import 'package:near_drop/transport/domain/SignalingController.dart';
import 'package:near_drop/transport/domain/enums/FileReceiveResult.dart';
import 'package:near_drop/transport/domain/enums/FileSendResult.dart';
import 'package:near_drop/transport/domain/enums/MimeTypeGroup.dart';
import 'package:near_drop/transport/domain/enums/SendRequestAnswer.dart';
import 'package:near_drop/transport/domain/enums/SendResponse.dart';
import 'package:near_drop/transport/domain/models/Connection.dart';
import 'package:near_drop/transport/domain/models/Progress.dart';
import 'package:near_drop/transport/data/dto/SendRequestDTO.dart';
import 'package:near_drop/transport/data/dto/SendRequestFilesDTO.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/entity/Device.dart';
import 'event_args/ConnectionCreatedEventArgs.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Steuert den Transportprozess zwischen Geräten.
class TransportController
{
    static const String FOLDER_NAME = "Near Drop";
    Directory? _downloadsDirectory;

    final SignalingController _signalingController;
    final TransportGateway _transportGateway;

    TransportController(this._signalingController, this._transportGateway);

    /// Startet den Signalisierungsprozess, wartet auf eingehende Verbindungen und initialisiert grundlegende Einstellungen.
    Future<void> init() async
    {
        _downloadsDirectory = await _getDownloadsDirectory();
        if (_downloadsDirectory == null)
        {
            print("Zugriff auf den Download-Ordner nicht möglich.");
            return;
        }

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
            await args.connection.close();
            args.device.connection = null;
            return;
        }

        if (sendRequest == null)
        {
            print("Ungültige Sendeanfrage empfangen.");
            await args.connection.close();
            args.device.connection = null;
            return;
        }

        // Je nach Typ der Sendeanfrage verarbeiten
        if (sendRequest is SendRequestFilesDTO)
        {
            await _handleReceiveFiles(sendRequest, args.connection, args.device);
        }
        else
        {
            await args.connection.close();
            args.device.connection = null;
        }
    }

    /// Verarbeitet die eingehende Sendeanfrage.
    Future<void> _handleReceiveFiles(SendRequestFilesDTO sendRequest, Connection connection, Device device) async
    {
        // Dem Benutzer die Anfrage anzeigen
        print("Sendeanfrage-Dialog wird angezeigt");
        SendRequestAnswer answer = await _showSendRequestDialog(device, sendRequest.filesCount, sendRequest.totalSize, sendRequest.mimeTypeGroup);

        // Antwort senden
        try
        {
            await connection.networkStream!.writeString(answer.name);
        }
        on Exception catch (e)
        {
            print("Fehler beim Senden der Antwort: $e");
            device.communicationInfo.setErrorState(ErrorState.error);
            await connection.close();
            device.connection = null;
            return;
        }

        // Wenn der Benutzer die Anfrage nicht akzeptiert hat, Verbindung schließen
        if (answer != SendRequestAnswer.accepted)
        {
            await connection.close();
            device.connection = null;
            return;
        }

        // Dateien empfangen
        device.communicationInfo.setReceiving(0);
        Progress progress = Progress(sendRequest.totalSize);
        for (int i = 0; i < sendRequest.filesCount; i++)
        {
            try
            {
                FileReceiveResult result = await _transportGateway.receiveFile(device, connection.networkStream!, progress, _downloadsDirectory!);

                if (result == FileReceiveResult.error)
                {
                    print("Fehler beim Empfangen der Datei.");
                    device.communicationInfo.setErrorState(ErrorState.error);
                    await connection.close();
                    device.connection = null;
                    return;
                }
            }
            catch (e)
            {
                print("Fehler beim Empfangen der Datei: $e");
                device.communicationInfo.setErrorState(ErrorState.error);
                await connection.close();
                device.connection = null;
                return;
            }
        }

        // Status auf "Erfolg" setzen und Verbindung schließen
        device.communicationInfo.setSuccessState(SuccessState.receivedSuccessfully);
        await connection.close();
        device.connection = null;
    }

    /// Gibt den Ordner zurück, in den empfangene Dateien gespeichert werden soll.
    Future<Directory?> _getDownloadsDirectory() async
    {
        Directory? targetDirectory;

        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
        {
            targetDirectory = await getDownloadsDirectory();
        }
        else if (Platform.isAndroid || Platform.isIOS)
        {
            // Öffentlicher Download-Ordner
            String path = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOAD);
            targetDirectory = Directory(join(path, FOLDER_NAME));
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

    /// Zeigt ein Dialogfeld an, um die Sendeanfrage des Geräts zu akzeptieren oder abzulehnen.
    Future<SendRequestAnswer> _showSendRequestDialog(Device device, int filesCount, int totalSize, MimeTypeGroup mimeTypeGroup) async
    {
        if (NearbyPage.scaffoldKey.currentContext == null)
        {
            print("Fehler: ScaffoldContext ist null.");
            return SendRequestAnswer.error;
        }

        BuildContext context = NearbyPage.scaffoldKey.currentContext!;
        Completer<SendRequestAnswer> completer = Completer<SendRequestAnswer>();
        String mimeTypeString = "";

        switch (mimeTypeGroup)
        {
            case MimeTypeGroup.images:
                mimeTypeString = filesCount == 1
                    ? AppLocalizations.of(context)!.mime_type_image
                    : AppLocalizations.of(context)!.mime_type_images;
                break;
            case MimeTypeGroup.videos:
                mimeTypeString = filesCount == 1
                    ? AppLocalizations.of(context)!.mime_type_video
                    : AppLocalizations.of(context)!.mime_type_videos;
                break;
            case MimeTypeGroup.audios:
                mimeTypeString = filesCount == 1
                    ? AppLocalizations.of(context)!.mime_type_audio
                    : AppLocalizations.of(context)!.mime_type_audios;
                break;
            case MimeTypeGroup.media:
                mimeTypeString = AppLocalizations.of(context)!.mime_type_media;
                break;
            default:
                mimeTypeString = AppLocalizations.of(context)!.mime_type_files;
        }

        showDialog(barrierDismissible: false, context: context, builder: (dialogContext) =>
            AlertDialog(
                actionsPadding: EdgeInsets.only(left: 24, right: 24, bottom: 16),
                title: Text(
                    AppLocalizations.of(context)!.send_request_dialog_title,
                    style: Theme.of(dialogContext).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w500),
                ),
                content: Text(AppLocalizations.of(context)!.send_request_dialog_content(device.firstname, filesCount, mimeTypeString)),
                actions: [
                    TextButton(onPressed: () {
                        completer.complete(SendRequestAnswer.declined);
                        Navigator.pop(dialogContext);
                    }, child: Text(AppLocalizations.of(context)!.decline_button)),
                    TextButton(onPressed: () {
                        completer.complete(SendRequestAnswer.accepted);
                        Navigator.pop(dialogContext);
                    }, child: Text(AppLocalizations.of(context)!.accept_button)),
                ],
            )
        );

        return await completer.future;
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
            else if (sendResult == FileSendResult.error)
            {
                print("Fehler beim Senden der Datei.");
                return SendResponse.receiverError;
            }
        }

        return SendResponse.ok;
    }
}