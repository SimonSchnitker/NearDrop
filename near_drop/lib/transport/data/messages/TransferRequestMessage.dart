import 'package:near_drop/transport/data/messages/ControlMessage.dart';
import '../../../tools/MimeTypeHelper.dart';

class TransferRequestMessage extends ControlMessage
{
    static const String label = "transfer-request";

    int filesCount;
    int totalSize;
    MimeTypeGroup mimeTypeGroup;

    TransferRequestMessage(this.filesCount, this.totalSize, this.mimeTypeGroup) : super(label);

    Map<String, dynamic> toMap()
    {
        return {
            "type": label,
            "filesCount": filesCount,
            "totalSize": totalSize,
            "mimeTypeGroup": mimeTypeGroup.name,
        };
    }
}