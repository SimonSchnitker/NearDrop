import 'package:near_drop/core/entity/Device.dart';
import 'package:near_drop/transport/domain/models/Connection.dart';

class ConnectionCreatedEventArgs
{
    Device device;
    Connection connection;
    int connectionId;

    ConnectionCreatedEventArgs(this.device, this.connection, this.connectionId);
}