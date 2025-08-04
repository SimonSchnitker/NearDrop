import 'package:near_drop/transport/data/messages/ControlMessage.dart';

class FileReadyMessage extends ControlMessage
{
    static const String label = "file-ready";

    FileReadyMessage() : super(label);

    Map<String, dynamic> toMap()
    {
        return {
            "type": label,
        };
    }
}