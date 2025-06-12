import 'dart:io';

class NsdDeviceSpottedEventArgs
{
    String? host;
    List<InternetAddress>? addresses;
    int port;
    String nearbyUuid;

    NsdDeviceSpottedEventArgs({required this.port, required this.nearbyUuid, this.host, this.addresses});
}