/// Gibt die Dateigröße in einem lesbaren Format zurück.
String getFileSizeString(int size)
{
    if (size <= 0)
    {
        return "0 Bytes";
    }
    else if (size < 1000) {
        return "$size Bytes";
    }
    else if (size < 1000000) {
        return "${(size / 1000).toStringAsFixed(2)} KB";
    }
    else if (size < 1000000000) {
        return "${(size / 1000000).toStringAsFixed(2)} MB";
    }
    else {
        return "${(size / 1000000000).toStringAsFixed(2)} GB";
    }
}