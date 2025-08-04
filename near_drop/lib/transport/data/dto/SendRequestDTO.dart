import 'package:near_drop/transport/domain/enums/MimeTypeGroup.dart';

class SendRequestDTO
{
    int filesCount;
    int totalSize;
    MimeTypeGroup mimeTypeGroup;

    SendRequestDTO(this.filesCount, this.totalSize, this.mimeTypeGroup);
}