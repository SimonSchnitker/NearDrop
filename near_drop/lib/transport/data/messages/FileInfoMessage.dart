import 'ControlMessage.dart';

class FileInfoMessage extends ControlMessage
{
    static const String label = "file-info";

    final String name;
    final int size;
    final String mimeType;

    FileInfoMessage(this.name, this.size, this.mimeType) : super(label);

    Map<String, dynamic> toMap() {
        return {
            "type": label,
            "name": name,
            "size": size,
            "mimeType": mimeType,
        };
    }
}