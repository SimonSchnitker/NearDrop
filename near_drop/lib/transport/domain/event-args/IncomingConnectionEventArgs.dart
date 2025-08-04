import 'package:near_drop/core/domain/entity/Device.dart';
import 'package:near_drop/transport/domain/models/Connection.dart';

class IncomingConnectionEventArgs
{
    Device device;
    Connection connection;

    IncomingConnectionEventArgs(this.device, this.connection);
}