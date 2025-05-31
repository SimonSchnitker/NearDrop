import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:near_drop/transport/domain/enums/FileReceiveResult.dart';
import 'package:near_drop/transport/domain/enums/FileSendResult.dart';
import 'package:near_drop/transport/domain/enums/MimeTypeGroup.dart';
import 'package:near_drop/transport/domain/enums/SendRequestAnswer.dart';
import 'package:near_drop/transport/domain/enums/SendRequestType.dart';
import 'package:near_drop/transport/domain/enums/TransportFlag.dart';
import 'package:near_drop/transport/domain/models/RTCNetworkStream.dart';
import 'package:near_drop/transport/domain/models/Progress.dart';
import 'package:near_drop/transport/data/dto/SendRequestDTO.dart';
import 'package:near_drop/transport/domain/models/ReceivedFile.dart';
import 'package:path/path.dart';

import '../../core/domain/entity/Device.dart';
import 'dto/SendRequestFilesDTO.dart';

/// Diese Klasse ist für das Senden und Empfangen von Dateien über den Datenkanal verantwortlich.
class TransportGateway
{
    final int CHUNK_SIZE = 65536;
    final String CHUNK_FLAG = TransportFlag.chunk.name.toUpperCase();
    final String FILE_FLAG = TransportFlag.file.name.toUpperCase();
    final String FILE_SKIP_FLAG = TransportFlag.fileSkip.name.toUpperCase();
    final String ACK_FLAG = TransportFlag.ack.name.toUpperCase();
    final String CANCEL_FLAG = TransportFlag.cancel.name.toUpperCase();

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
    Future<bool> sendFileSkip(Device device, RTCNetworkStream stream, int length, Progress progress) async
    {
        // Flag an den Stream senden, dass eine Datei übersprungen wird
        await stream.writeString(FILE_SKIP_FLAG);

        // FileSkip-Informationen senden
        Map<String, dynamic> fileSkipMap = {
            "length": length,
        };

        await stream.writeString(jsonEncode(fileSkipMap));
        String response = await stream.readString();

        if (response != ACK_FLAG)
        {
            return false;
        }

        // Fortschritt aktualisieren
        progress.sentBytes += length;
        device.communicationInfo.setSending(progress.value);
        return true;
    }

    /// Sendet ein Cancel-Flag an den Stream, um eine laufende Übertragung abzubrechen.
    /// Diese Methode wird verwendet, wenn eine Datei nicht gelesen werden konnte und der Benutzer die gesamte Übertragung abbrechen möchte.
    Future<void> sendCancelFlag(RTCNetworkStream stream) async
    {
        await stream.writeString(CANCEL_FLAG);
    }

    /// Sendet eine Datei über den Stream.
    Future<FileSendResult> sendFile(Device device, RTCNetworkStream stream, File file, Progress progress) async
    {
        // Nur zum Testen: Simuliere einen Fehler beim Lesen der Datei
        /*
        if (Random().nextBool())
        {
            return FileSendResult.fileReadError;
        }
         */

        // Dateiinformationen sammeln
        String filename = basename(file.path);
        int fileLength = await file.length();
        String mimeType = lookupMimeType(file.path) ?? "";

        // Datei versuchen zu öffnen
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

        // Flag an den Stream senden, dass eine Datei gesendet wird
        await stream.writeString(FILE_FLAG);

        // Dateiinformationen senden
        Map<String, dynamic> fileInfo = {
            "filename": filename,
            "length": fileLength,
            "mimeType": mimeType,
        };
        await stream.writeString(jsonEncode(fileInfo));

        // Dateiinhalt in Chunks senden
        int bytesRead = 0;
        while (bytesRead < fileLength)
        {
            final chunk = await raf.read(CHUNK_SIZE);
            bytesRead += chunk.length;

            // Prüfen, ob der Benutzer das Abbrechen angefordert hat
            if (device.communicationInfo.cancelationRequested)
            {
                print("Dateiübertragung wird abgebrochen.");
                device.communicationInfo.setCanceling();
                await raf.close();
                await stream.writeString(CANCEL_FLAG);
                return FileSendResult.userCanceled;
            }

            // CHUNK_FLAG an den Stream senden
            await stream.writeString(CHUNK_FLAG);

            // Chunk an den Stream senden
            await stream.writeBinary(chunk);

            // Warten auf Antwort
            String response = await stream.readString();

            // Prüfen, ob der Empfänger das Senden abbrechen möchte
            if (response == CANCEL_FLAG)
            {
                print("Empfänger möchte die Dateiübertragung abbrechen.");
                await raf.close();
                return FileSendResult.userCanceled;
            }
            else if (response != ACK_FLAG)
            {
                print("Unerwartetes Flag empfangen: $response");
                await raf.close();
                return FileSendResult.wrongFlagOrParameter;
            }

            // Fortschritt aktualisieren
            progress.sentBytes += chunk.length;
            device.communicationInfo.setSending(progress.value);
        }

        await raf.close();
        return FileSendResult.ok;
    }

    /// Empfängt eine Datei über den Stream.
    Future<FileReceiveResult> receiveFile(Device device, RTCNetworkStream stream, Progress progress, Directory targetDirectory, ReceivedFile receivedFile) async
    {
        // Flag empfangen
        String flag = await stream.readString();

        if (flag == CANCEL_FLAG)
        {
            print("Sender möchte die Dateiübertragung abbrechen.");
            return FileReceiveResult.userCanceled;
        }
        else if (flag == FILE_SKIP_FLAG)
        {
            String payload = await stream.readString();
            Map<String, dynamic> fileSkipMap = jsonDecode(payload);
            if (!fileSkipMap.containsKey("length"))
            {
                print("Üngültige Parameter in der fileSkipMap: $fileSkipMap");
                return FileReceiveResult.wrongParameters;
            }

            // Fortschritt direkt setzen
            int fileLength = fileSkipMap["length"];
            progress.sentBytes += fileLength;
            device.communicationInfo.setReceiving(progress.value);

            // Bestätigung senden
            await stream.writeString(ACK_FLAG);
            return FileReceiveResult.skipped;
        }
        else if (flag != FILE_FLAG)
        {
            print("Unbekanntes Flag empfangen: $flag");
            return FileReceiveResult.error;
        }

        // Dateiinformationen empfangen
        String payload = await stream.readString();
        Map<String, dynamic> fileInfoMap = jsonDecode(payload);

        if (!fileInfoMap.containsKey("length") || !fileInfoMap.containsKey("filename") || !fileInfoMap.containsKey("mimeType"))
        {
            print("Üngültige Parameter in der fileInfoMap: $fileInfoMap");
            return FileReceiveResult.wrongParameters;
        }

        int fileLength = fileInfoMap["length"];
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

        // Dateiinformationen in das ReceivedFile-Objekt schreiben
        receivedFile.name = filename;
        receivedFile.path = file.path;
        receivedFile.size = fileLength;
        receivedFile.mimeType = mimeType;
        receivedFile.raf = raf;

        int bytesReceived = 0;
        while (bytesReceived < fileLength)
        {
            String flag = await stream.readString();

            // Prüfen, ob der Sender das Senden abbrechen möchte
            if (flag == CANCEL_FLAG)
            {
                print("Dateiübertragung wird abgebrochen.");
                await raf.close();
                return FileReceiveResult.userCanceled;
            }
            else if (flag != CHUNK_FLAG)
            {
                print("Unbekanntes Flag: $flag");
                await raf.close();
                return FileReceiveResult.error;
            }

            final chunk = await stream.readBinary();
            bytesReceived += chunk.length;

            // Chunk in die Datei schreiben
            await raf.writeFrom(chunk);

            // Prüfen, ob der Benutzer das Abbrechen angefordert hat
            if (device.communicationInfo.cancelationRequested)
            {
                print("Dateiübertragung wird abgebrochen.");
                await raf.close();
                await stream.writeString(CANCEL_FLAG);
                return FileReceiveResult.userCanceled;
            }

            // Bestätigung senden
            await stream.writeString(ACK_FLAG);

            // Fortschritt aktualisieren
            progress.sentBytes += chunk.length;
            device.communicationInfo.setReceiving(progress.value);
        }

        await raf.close();
        receivedFile.fullyReceived = true; // Flag setzen, dass die Datei vollständig empfangen wurde
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