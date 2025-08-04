import 'package:near_drop/transport/domain/models/Connection.dart';
import '../../../core/domain/entity/Device.dart';

/// Diese Klasse enthält die Argumente für das Ereignis, wenn eine Verbindung hergestellt wurde.
/// Wird verwendet, wenn sich ein Gerät mit uns verbunden hat.
class ConnectionCreatedEventArgs
{
    Device device;
    Connection connection;
    int connectionId;

    ConnectionCreatedEventArgs(this.device, this.connection, this.connectionId);
}