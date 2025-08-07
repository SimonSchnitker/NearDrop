import 'dart:io';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:near_drop/core/domain/enums/SuccessState.dart';
import 'package:near_drop/transport/data/Receiver.dart';
import 'package:near_drop/transport/data/Sender.dart';
import 'package:near_drop/transport/data/dto/ReceivedFileDTO.dart';
import 'package:near_drop/transport/data/dto/SendRequestDTO.dart';
import 'package:near_drop/transport/domain/SignalingController.dart';
import 'package:near_drop/transport/domain/TransportDialogs.dart';
import 'package:near_drop/transport/domain/enums/MimeTypeGroup.dart';
import 'package:near_drop/transport/domain/event-args/IncomingConnectionEventArgs.dart';
import 'package:near_drop/transport/domain/models/Connection.dart';
import 'package:near_drop/transport/domain/models/ReceivedFile.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../Runtime.dart';
import '../../core/domain/entity/Device.dart';
import '../../core/domain/enums/ErrorState.dart';
import '../../main.dart';
import '../../nearby/presentation/pages/NearbyPage.dart';
import 'enums/SendResponse.dart';
import 'package:external_path/external_path.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:gal/gal.dart';
import 'package:native_exif/native_exif.dart';

/// Steuert den Transportprozess zwischen Geräten.
class TransportController
{
    static const String _folderName = Runtime.appName;
    static const int minBytesForDataVolumeWarning = 30 * 1024 * 1024; // 30 MB

    final SignalingController _signalingController;
    Directory? filesDirectory;

    TransportController(this._signalingController);

    /// Initialisiert den Zielordner, in den empfangene Dateien gespeichert werden sollen.
    Future<bool> initFilesDirectory() async
    {
        try
        {
            if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
            {
                filesDirectory = await getDownloadsDirectory();
            }
            else if (Platform.isAndroid)
            {
                // Öffentlicher Download-Ordner
                String path = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOAD);
                filesDirectory = Directory(join(path, _folderName));
            }
            else if (Platform.isIOS)
            {
                filesDirectory = await getApplicationDocumentsDirectory();
            }

            if (await filesDirectory?.exists() == false)
            {
                filesDirectory = await filesDirectory?.create(recursive: true);
            }

            if (filesDirectory != null && await filesDirectory!.exists())
            {
                Receiver.setFilesDirectory(filesDirectory!);
                return true;
            }

            dprint("Zielordner konnte nicht erstellt oder gefunden werden.");
            return false;
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
        _signalingController.onIncomingConnection.stream.listen(_onIncomingConnection);
        _signalingController.startListening();
        dprint("Signalisierung gestartet.");
    }

    Future<void> cancelTransport(Device device) async
    {
        //Connection? connection = _signalingController.getConnection(connectionId);
    }

    /// Sendet Dateien an ein Gerät.
    Future<SendResponse> sendFiles(Device device, List<File> files) async
    {
        //await device.closeCurrentConnection(); // Aktuelle Verbindung zum Gerät schließen, falls vorhanden
        device.communicationInfo.setConnecting();

        // Gesamtgröße und MIME-Typ-Gruppe der Dateien ermitteln
        int totalSize = 0;
        MimeTypeGroup mimeTypeGroup = MimeTypeGroup.mixed;
        try
        {
            totalSize = await _getTotalFileSize(files);
            mimeTypeGroup = _getMimeTypeGroup(files);
        }
        on FileSystemException catch (e)
        {
            device.communicationInfo.setErrorState(ErrorState.error);
            return SendResponse.fileAccessError;
        }

        // Verbindung zum Gerät herstellen
        Connection? connection = await _signalingController.connect(device);
        if (connection == null)
        {
            device.communicationInfo.setErrorState(ErrorState.error);
            return SendResponse.connectionError;
        }

        final sender = Sender(connection.dataChannel!, connection.controlChannel!);

        // Sendeanfrage stellen
        device.communicationInfo.setRequesting();
        RequestResult requestResult = await sender.request(files.length, totalSize, mimeTypeGroup);
        switch (requestResult)
        {
            case RequestResult.accepted:
                break;
            case RequestResult.declined:
                return SendResponse.receiverDeclined;
            case RequestResult.timeout:
                return SendResponse.timeout;
            case RequestResult.connectionError:
                return SendResponse.connectionError;
        }

        // Dateien senden
        device.communicationInfo.setSending(0);
        await sender.start(files, (progress) {
            device.communicationInfo.setSending(progress);
        });
        SendResult sendResult = await sender.isFinished;

        _signalingController.closeConnection(connection.connectionId); // Nicht darauf warten!
        sender.dispose();

        switch (sendResult)
        {
            case SendResult.ok:
                device.communicationInfo.setSuccessState(SuccessState.sendedSuccessfully);
                return SendResponse.ok;
            case SendResult.userCanceled:
                device.communicationInfo.setErrorState(ErrorState.userCanceled);
                return SendResponse.userCanceled;
            case SendResult.timeout:
                device.communicationInfo.setErrorState(ErrorState.error);
                return SendResponse.timeout;
            case SendResult.connectionError:
                device.communicationInfo.setErrorState(ErrorState.error);
                return SendResponse.connectionError;
        }
    }

    /// Berechnet die Gesamtgröße der übergebenen Dateien.
    Future<int> _getTotalFileSize(List<File> files) async
    {
        int totalSize = 0;
        for (File file in files)
        {
            totalSize += await file.length();
        }
        return totalSize;
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

    /// Wirf aufgerufen, wenn eine Verbindung von einem anderen Gerät eingegangen ist.
    Future<void> _onIncomingConnection(IncomingConnectionEventArgs args) async
    {
        final receiver = Receiver(args.connection.dataChannel!, args.connection.controlChannel!);
        final List<ReceivedFile> receivedFiles = [];
        MimeTypeGroup mimeTypeGroup = MimeTypeGroup.mixed; // Wird bei Sendeanfrage gesetzt

        receiver.listen(
            (SendRequestDTO sendRequest) async {
                mimeTypeGroup = sendRequest.mimeTypeGroup;
                bool answer = await showSendRequestDialog(args.device, sendRequest.filesCount, sendRequest.totalSize, sendRequest.mimeTypeGroup);
                answer == true ? await receiver.sendAccept() : await receiver.sendDecline();
            }, (ReceivedFileDTO dto) async {
                dprint("Empfangene Datei: ${dto.name}, Größe: ${dto.size} Bytes, MIME-Typ: ${dto.mimeType}");
                final receivedFile = ReceivedFile(dto.name, dto.path, dto.size, dto.mimeType);
                receivedFiles.add(receivedFile);

                DateTime now = DateTime.now();
                await _modifyCreationDate(receivedFile, now);
                await _modifyExif(receivedFile, now);
                await _scanFile(receivedFile);
        }, (double progress) {
            args.device.communicationInfo.setReceiving(progress);
        });

        ReceiveResult response = await receiver.isFinished;
        if (response == ReceiveResult.ok)
        {
            args.device.communicationInfo.setSuccessState(SuccessState.receivedSuccessfully);
        }
        else if (response == ReceiveResult.fileWriteError || response == ReceiveResult.connectionError)
        {
            args.device.communicationInfo.setErrorState(ErrorState.error);
            await receiver.deleteCurrentBrokenFile();
            await _deleteReceivedFiles(receivedFiles);
        }
        else if (response == ReceiveResult.userCanceled)
        {
            args.device.communicationInfo.setErrorState(ErrorState.userCanceled);
            await receiver.deleteCurrentBrokenFile();
            await _deleteReceivedFiles(receivedFiles);
        }

        _signalingController.closeConnection(args.connection.connectionId);
        receiver.dispose();

        // Dialog mit den empfangenen Dateien anzeigen
        await showImagePreviewDialog(context: NearbyPage.scaffoldKey.currentContext!, allFiles: receivedFiles, device: args.device, targetDirectory: filesDirectory, mimeTypeGroup: mimeTypeGroup);
    }

    /// Löscht alle empfangenen Dateien.
    /// Wird genutzt, wenn der Empfang nicht vollständig erfolgreich war.
    Future<void> _deleteReceivedFiles(List<ReceivedFile> receivedFiles) async
    {
        for (ReceivedFile file in receivedFiles)
        {
            try
            {
                File(file.path).delete();
            }
            catch (e)
            {
                // Ignorieren
            }
        }
    }

    /// Modifiziert das Erstellungsdatum der empfangenen Datei.
    Future<void> _modifyCreationDate(ReceivedFile receivedFile, DateTime dateTime) async
    {
        final file = File(receivedFile.path);

        // Erstellungdatum der Datei auf das aktuelle Datum setzen
        try
        {
            await file.setLastAccessed(dateTime);
            await file.setLastModified(dateTime);
        }
        catch (e)
        {
            dprint("Fehler beim Setzen des Erstellungsdatums: $e");
        }
    }

    /// Modifiziert die Exif-Daten der empfangenen Datei, falls es sich um ein Bild handelt.
    Future<void> _modifyExif(ReceivedFile receivedFile, DateTime dateTime) async
    {
        if ((Platform.isAndroid || Platform.isIOS) && receivedFile.isImage)
        {
            String nowFormatted = DateFormat("yyyy:MM:dd HH:mm:ss").format(dateTime);
            Exif? exif;
            try
            {
                exif = await Exif.fromPath(receivedFile.path);
                await exif.writeAttributes({
                    "DateTimeOriginal": nowFormatted,
                    "DateTimeDigitized": nowFormatted,
                    "DateTime": nowFormatted,
                });
            }
            catch (e)
            {
                dprint("Fehler beim Modifizieren der Exif-Daten: $e");
            }
            finally
            {
                await exif?.close();
            }
        }
    }

    /// Kümmert sich darum, dass eine Datei unter Android und iOS vom System erkannt wird und in den entsprechenden Apps angezeigt wird.
    Future<void> _scanFile(ReceivedFile file) async
    {
        if (Platform.isAndroid)
        {
            await MediaScanner.loadMedia(path: file.path);
        }
        else if (Platform.isIOS && file.isMediaFile)
        {
            if (await Gal.requestAccess(toAlbum: true))
            {
                if (file.isImage)
                {
                    await Gal.putImage(file.path, album: _folderName);
                }
                else if (file.isVideo)
                {
                    await Gal.putVideo(file.path, album: _folderName);
                }
            }
        }
    }
}