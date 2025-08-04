import 'package:near_drop/transport/data/messages/ControlMessage.dart';

class TransferFinishedMessage extends ControlMessage
{
    static const String label = "transfer-finished";

    TransferFinishedMessage() : super(label);

    Map<String, dynamic> toMap()
    {
        return {
            "type": label,
        };
    }
}