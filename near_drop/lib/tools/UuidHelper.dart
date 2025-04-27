import 'package:uuid/uuid.dart';

/// Hilfsklasse für UUIDs.
class UuidHelper
{
    static const String NEARBY_UUID_PREFIX = "1b7e68a9"; // Alle Geräte-UUIDs beginnen mit dieser Konstante

    /// Generiert eine UUID für ein Gerät.
    static String getRandomDeviceUUID()
    {
        String uuid = Uuid().v4();
        uuid = uuid.substring(NEARBY_UUID_PREFIX.length, uuid.length);
        return NEARBY_UUID_PREFIX + uuid;
    }

    /// Überprüft, ob eine UUID eines Gerätes gültig ist.
    static bool isValidDeviceUUID(String uuid)
    {
        if (Uuid.isValidUUID(fromString: uuid) && uuid.startsWith(NEARBY_UUID_PREFIX))
        {
            return true;
        }

        return false;
    }
}