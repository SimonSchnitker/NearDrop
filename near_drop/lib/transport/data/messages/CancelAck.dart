import 'package:near_drop/transport/data/messages/ControlMessage.dart';

class CancelAck extends ControlMessage
{
    static const String label = "cancel-ack";

    CancelAck() : super(label);

    Map<String, dynamic> toMap() {
        return {
            "type": label,
        };
    }
}