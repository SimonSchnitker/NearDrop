import 'package:near_drop/transport/domain/enums/SendRequestType.dart';

/// Beinhaltet die Info, welche Art von Anfrage empfangen wurde.
class SendRequestDTO
{
    SendRequestType type;

    SendRequestDTO(this.type);
}