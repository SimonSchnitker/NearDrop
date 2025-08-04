import 'package:near_drop/transport/data/messages/ControlMessage.dart';

class FileReceivedMessage extends ControlMessage
{
    static const String label = "file-received";

    FileReceivedMessage() : super(label);

    Map<String, dynamic> toMap()
    {
        return {
            "type": label,
        };
    }
}