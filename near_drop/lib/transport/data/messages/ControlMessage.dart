import 'package:near_drop/main.dart';
import 'package:near_drop/transport/data/messages/CancelAck.dart';
import 'package:near_drop/transport/data/messages/CancelMessage.dart';
import 'package:near_drop/transport/data/messages/FileInfoMessage.dart';
import 'package:near_drop/transport/data/messages/FileReadyMessage.dart';
import 'package:near_drop/transport/data/messages/FileReceivedMessage.dart';
import 'package:near_drop/transport/data/messages/ProgressMessage.dart';
import 'package:near_drop/transport/data/messages/TransferAcceptMessage.dart';
import 'package:near_drop/transport/data/messages/TransferDeclineMessage.dart';
import 'package:near_drop/transport/data/messages/TransferFinishedMessage.dart';
import 'package:near_drop/transport/data/messages/TransferRequestMessage.dart';
import 'package:near_drop/transport/domain/enums/MimeTypeGroup.dart';

abstract class ControlMessage
{
    String type;

    ControlMessage(this.type);

    static ControlMessage fromMap(Map<String, dynamic> map)
    {
        final type = map["type"] as String;

        switch (type)
        {
            case TransferRequestMessage.label:
                int filesCount = map["filesCount"] as int;
                int totalSize = map["totalSize"] as int;
                MimeTypeGroup mimeTypeGroup = MimeTypeGroup.values.byName(map["mimeTypeGroup"] as String);
                return TransferRequestMessage(filesCount, totalSize, mimeTypeGroup);
            case FileReadyMessage.label:
                return FileReadyMessage();
            case TransferAcceptMessage.label:
                return TransferAcceptMessage();
            case TransferDeclineMessage.label:
                return TransferDeclineMessage();
            case TransferFinishedMessage.label:
                return TransferFinishedMessage();
            case CancelMessage.label:
                return CancelMessage();
            case CancelAck.label:
                return CancelAck();
            case FileReceivedMessage.label:
                return FileReceivedMessage();
            case ProgressMessage.label:
                double progress = map["progress"] as double;
                return ProgressMessage(progress);
            case FileInfoMessage.label:
                String fileName = map["name"] as String;
                int fileSize = map["size"] as int;
                String mimeType = map["mimeType"] as String;
                return FileInfoMessage(fileName, fileSize, mimeType);
            default:
                throw Exception("Unknown control message type: $type");
        }
    }
}