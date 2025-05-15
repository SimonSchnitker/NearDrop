import 'package:near_drop/transport/domain/enums/MimeTypeGroup.dart';
import '../../domain/enums/SendRequestType.dart';
import 'SendRequestDTO.dart';

/// Beinhaltet die Informationen, die für den Empfang von Dateien benötigt werden.
class SendRequestFilesDTO extends SendRequestDTO
{
    int filesCount;
    int totalSize;
    MimeTypeGroup mimeTypeGroup;

    SendRequestFilesDTO(this.filesCount, this.totalSize, this.mimeTypeGroup) : super(SendRequestType.files);
}