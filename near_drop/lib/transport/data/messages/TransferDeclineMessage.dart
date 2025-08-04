import 'package:near_drop/transport/data/messages/ControlMessage.dart';

class TransferDeclineMessage extends ControlMessage
{
    static const String label = "transfer-decline";

    TransferDeclineMessage() : super(label);

    Map<String, dynamic> toMap()
    {
        return {
            "type": label,
        };
    }
}