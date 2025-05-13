import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:near_drop/nearby/presentation/pages/NearbyPage.dart';
import 'package:near_drop/transport/data/TransportGateway.dart';
import 'package:near_drop/transport/domain/SignalingController.dart';
import 'package:near_drop/transport/domain/enums/MimeTypeGroup.dart';
import 'package:near_drop/transport/domain/enums/SendRequestAnswer.dart';
import 'package:near_drop/transport/domain/enums/SendResponse.dart';
import 'package:near_drop/transport/domain/models/Connection.dart';
import '../../core/entity/Device.dart';
import 'event_args/ConnectionCreatedEventArgs.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Steuert den Transportprozess zwischen Geräten.
class TransportController
{
    final SignalingController _signalingController;
    final TransportGateway _transportGateway;

    TransportController(this._signalingController, this._transportGateway);

    /// Startet den Signalisierungsprozess und wartet auf eingehende Verbindungen.
    void startSignalingListening()
    {
        _signalingController.onConnectionCreated.stream.listen(_onConnectionCreated);

        _signalingController.startListening();
        print("Signalisierung gestartet");
    }

    /// Wird aufgerufen, wenn sich ein Gerät mit uns verbunden hat.
    Future<void> _onConnectionCreated(ConnectionCreatedEventArgs args) async
    {
        int filesCount = 0;
        int totalSize = 0;
        MimeTypeGroup mimeTypeGroup = MimeTypeGroup.mixed;

        // Sendeanfrage empfangen
        try
        {
            String request = await args.connection.networkStream!.readString();
            Map<String, dynamic> payload = jsonDecode(request);
            filesCount = payload["filesCount"];
            totalSize = payload["totalSize"];
            mimeTypeGroup = MimeTypeGroup.values.byName(payload["mimeTypes"]);
        }
        on Exception catch (e)
        {
            print("Fehler beim Empfangen der Anfrage: $e");
            await args.connection.close();
            return;
        }

        // Dem Benutzer die Anfrage anzeigen
        SendRequestAnswer answer = await _showSendRequestDialog(args.device, filesCount, totalSize, mimeTypeGroup);

        // Antwort senden
        try
        {
            await args.connection.networkStream!.writeString(answer.name);
        }
        on Exception catch (e)
        {
            print("Fehler beim Senden der Antwort: $e");
            await args.connection.close();
            return;
        }

        // Wenn die Anfrage abgelehnt wurde, Verbindung schließen
        if (answer == SendRequestAnswer.declined)
        {
            await Future.delayed(const Duration(seconds: 2)); // Kurz warten, um sicherzustellen, dass die Antwort gesendet wurde
            await args.connection.close();
            return;
        }
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

        return SendResponse.ok;
    }
}