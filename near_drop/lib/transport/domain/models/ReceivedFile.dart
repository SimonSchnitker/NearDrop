import 'dart:io';

/// Definiert den Aufbau einer empfangenen Datei.
class ReceivedFile
{
    String name = "";
    String path = "";
    int size = 0;
    String mimeType = "";
    RandomAccessFile? raf;
    bool fullyReceived = false;

    get isMediaFile => mimeType.startsWith("image/") || mimeType.startsWith("video/");
    get isImage => mimeType.startsWith("image/");
    get isVideo => mimeType.startsWith("video/");
}