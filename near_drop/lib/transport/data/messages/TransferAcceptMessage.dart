import 'package:near_drop/transport/data/messages/ControlMessage.dart';

class TransferAcceptMessage extends ControlMessage
{
    static const String label = "transfer-accept";

    TransferAcceptMessage() : super(label);

    Map<String, dynamic> toMap()
    {
        return {
            "type": label,
        };
    }
}