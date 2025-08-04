/// Definiert den Aufbau einer empfangenen Datei.
class ReceivedFile
{
    String name;
    String path;
    int size;
    String mimeType;

    get isMediaFile => mimeType.startsWith("image/") || mimeType.startsWith("video/");
    get isImage => mimeType.startsWith("image/");
    get isVideo => mimeType.startsWith("video/");

    ReceivedFile(this.name, this.path, this.size, this.mimeType);
}