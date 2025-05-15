import 'dart:convert';
import 'dart:io';
import 'package:media_scanner/media_scanner.dart';
import 'package:mime/mime.dart';
import 'package:near_drop/core/entity/Device.dart';
import 'package:near_drop/transport/domain/enums/FileReceiveResult.dart';
import 'package:near_drop/transport/domain/enums/FileSendResult.dart';
import 'package:near_drop/transport/domain/enums/MimeTypeGroup.dart';
import 'package:near_drop/transport/domain/enums/SendFileAction.dart';
import 'package:near_drop/transport/domain/enums/SendRequestAnswer.dart';
import 'package:near_drop/transport/domain/enums/SendRequestType.dart';
import 'package:near_drop/transport/domain/enums/TransportFlag.dart';
import 'package:near_drop/transport/domain/models/RTCNetworkStream.dart';
import 'package:near_drop/transport/domain/models/Progress.dart';
import 'package:near_drop/transport/data/dto/SendRequestDTO.dart';
import 'package:path/path.dart';

import 'dto/SendRequestFilesDTO.dart';

/// Diese Klasse ist für das Senden und Empfangen von Dateien über den Datenkanal verantwortlich.
class TransportGateway
{
    final int CHUNK_SIZE = 65536;
    final String CHUNK_FLAG = TransportFlag.chunk.name.toUpperCase();
    final String ACK_FLAG = TransportFlag.ack.name.toUpperCase();
    final String SKIP_FLAG = "SKIP";

    /// Schreibt eine Sendeanfrage an den Stream und wartet auf eine Antwort.
    Future<SendRequestAnswer> request(RTCNetworkStream stream, int filesCount, int totalSize, MimeTypeGroup mimeTypeGroup) async
    {
        Map<String, dynamic> payload = {
            "type": SendRequestType.files.name,
            "filesCount": filesCount,
            "totalSize": totalSize,
            "mimeTypeGroup": mimeTypeGroup.name,
        };

        await stream.writeString(jsonEncode(payload));
        String response = await stream.readString();
        return SendRequestAnswer.values.byName(response);
    }

    /// Empfängt eine Sendeanfrage über den Stream.
    Future<SendRequestDTO?> receiveRequest(RTCNetworkStream stream) async
    {
        String payload = await stream.readString();
        Map<String, dynamic> requestInfo = jsonDecode(payload);

        if (!requestInfo.containsKey("type"))
        {
            print("Fehlende Parameter in der Anfrage: $requestInfo");
            return null;
        }

        String type = requestInfo["type"];
        if (type != SendRequestType.files.name)
        {
            print("Unbekannter SendRequestType: $type");
            return null;
        }

        if (!requestInfo.containsKey("filesCount") || !requestInfo.containsKey("totalSize") || !requestInfo.containsKey("mimeTypeGroup"))
        {
            print("Fehlende Parameter in der Anfrage: $requestInfo");
            return null;
        }

        int filesCount = requestInfo["filesCount"];
        int totalSize = requestInfo["totalSize"];
        MimeTypeGroup mimeTypeGroup = MimeTypeGroup.values.byName(requestInfo["mimeTypeGroup"]);
        return SendRequestFilesDTO(filesCount, totalSize, mimeTypeGroup);
    }

    /// Sendet eine Info an den Stream, dass die nächste Datei übersprungen werden soll.
    Future<bool> sendFileSkip(RTCNetworkStream stream, int length) async
    {
        Map<String, dynamic> skipInfo = {
            "action": SendFileAction.skip.name,
            "length": length,
        };

        await stream.writeString(jsonEncode(skipInfo));
        String response = await stream.readString();
        return response == ACK_FLAG;
    }

    /// Sendet eine Datei über den Stream.
    Future<FileSendResult> sendFile(Device device, RTCNetworkStream stream, File file, Progress progress) async
    {
        String filename = basename(file.path);
        int fileLength = await file.length();
        String mimeType = lookupMimeType(file.path) ?? "";

        // Dateiinformationen senden
        Map<String, dynamic> fileInfo = {
            "action": SendFileAction.file.name,
            "filename": filename,
            "length": fileLength,
            "mimeType": mimeType,
        };
        await stream.writeString(jsonEncode(fileInfo));

        // Dateiinhalt senden
        final RandomAccessFile raf;
        try
        {
            raf = await file.open();
        }
        on FileSystemException catch (e)
        {
            print("Fehler beim Öffnen der Datei: $e");
            return FileSendResult.fileReadError;
        }

        int bytesRead = 0;
        while (bytesRead < fileLength)
        {
            final chunk = await raf.read(CHUNK_SIZE);
            bytesRead += chunk.length;

            // Chunk an den Stream senden
            await stream.writeBinary(chunk);

            // Warten auf Bestätigung
            String response = await stream.readString();

            if (response != ACK_FLAG)
            {
                print("Fehler beim Senden der Datei: $response");
                await raf.close();
                return FileSendResult.error;
            }

            // Fortschritt aktualisieren
            progress.sentBytes += chunk.length;
            device.communicationInfo.setSending(progress.value);
        }

        await raf.close();
        return FileSendResult.ok;
    }

    /// Empfängt eine Datei über den Stream.
    Future<FileReceiveResult> receiveFile(Device device, RTCNetworkStream stream, Progress progress, Directory targetDirectory) async
    {
        // Payload empfangen
        String payload = await stream.readString();
        Map<String, dynamic> fileInfoMap = jsonDecode(payload);

        if (!fileInfoMap.containsKey("action") || !fileInfoMap.containsKey("length"))
        {
            print("Fehlende Parameter in der fileInfoMap: $fileInfoMap");
            return FileReceiveResult.wrongParameters;
        }

        String action = fileInfoMap["action"];
        int fileLength = fileInfoMap["length"];

        // Wenn die Datei übersprungen werden soll, den Fortschritt direkt setzen
        if (action == SendFileAction.skip.name)
        {
            progress.sentBytes += fileLength;
            device.communicationInfo.setReceiving(progress.value);
            return FileReceiveResult.skipped;
        }

        if (action != SendFileAction.file.name)
        {
            print("Unbekannte Aktion: $action");
            return FileReceiveResult.error;
        }

        if (!fileInfoMap.containsKey("filename") || !fileInfoMap.containsKey("mimeType"))
        {
            print("Fehlende Parameter in der fileInfoMap: $fileInfoMap");
            return FileReceiveResult.wrongParameters;
        }

        String filename = fileInfoMap["filename"];
        String mimeType = fileInfoMap["mimeType"];

        // Dateiinhalt empfangen
        final File file;
        final RandomAccessFile raf;
        try
        {
            file = await _createFile(targetDirectory, filename);
            raf = await file.open(mode: FileMode.writeOnly);
        }
        catch (e)
        {
            print("Fehler beim Öffnen der Datei: $e");
            return FileReceiveResult.fileWriteError;
        }

        int bytesReceived = 0;
        while (bytesReceived < fileLength)
        {
            final chunk = await stream.readBinary();
            bytesReceived += chunk.length;

            // Chunk in die Datei schreiben
            await raf.writeFrom(chunk);

            // Bestätigung senden
            await stream.writeString(ACK_FLAG);

            // Fortschritt aktualisieren
            progress.sentBytes += chunk.length;
            device.communicationInfo.setReceiving(progress.value);
        }

        // Wenn Datei ein Foto oder Video ist, MediaScanner unter Android anstoßen, um die Datei in der Galerie anzuzeigen
        if (Platform.isAndroid && (mimeType.startsWith("image/") || mimeType.startsWith("video/")))
        {
            await MediaScanner.loadMedia(path: file.path);
        }

        await raf.close();
        return FileReceiveResult.ok;
    }

    /// Erstellt eine Datei im angegebenen Ordner mit dem angegebenen Dateinamen.
    Future<File> _createFile(Directory directory, String filename) async
    {
        String ext = extension(filename);
        String filenameWithoutExt = basenameWithoutExtension(filename);
        File file = File(join(directory.path, filename));

        // Zahl hinter dem Dateinamen erhöhen, falls Datei bereits existiert
        int i = 1;
        while (await file.exists())
        {
            file = File(join(directory.path, "$filenameWithoutExt ($i)$ext"));
            i++;
        }

        return file;
    }
}