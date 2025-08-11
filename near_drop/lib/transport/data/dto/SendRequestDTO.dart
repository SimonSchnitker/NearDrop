import '../../../tools/MimeTypeHelper.dart';

class SendRequestDTO
{
    int filesCount;
    int totalSize;
    MimeTypeGroup mimeTypeGroup;

    SendRequestDTO(this.filesCount, this.totalSize, this.mimeTypeGroup);
}