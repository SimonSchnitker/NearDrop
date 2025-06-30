import '../../core/domain/entity/Device.dart';

/// Repräsentiert einen Austausch zwischen zwei Geräten.
class Exchange
{
    static const timeout = Duration(seconds: 3);

    DateTime sentAt = DateTime.now();
    bool acknowledgeReceived = false;
    bool deviceDataSent = false;
    Device? receivedDevice;

    bool get isSendExpired => DateTime.now().difference(sentAt) > timeout;
    bool get isFinished => acknowledgeReceived && deviceDataSent && receivedDevice != null;
}