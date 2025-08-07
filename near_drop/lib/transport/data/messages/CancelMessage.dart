import 'package:near_drop/transport/data/messages/ControlMessage.dart';

class CancelMessage extends ControlMessage
{
    static const String label = "cancel";

    CancelMessage() : super(label);

    Map<String, dynamic> toMap() {
        return {
            "type": label,
        };
    }
}