import 'dart:math';
import 'package:uuid/uuid.dart';

/// Hilfsklasse für UUIDs.
class IdHelper
{
    static const String NEARBY_UUID_PREFIX = "1b7e68a9"; // Alle Geräte-UUIDs beginnen mit dieser Konstante
    static const String KEY_LETTERS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"; // Erlaubte Zeichen für Geräte-Keys
    static const int KEY_LENGTH = 12; // Länge der Geräte-Keys

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

    /// Generiert einen zufälligen Schlüssel für ein Gerät.
    static String getRandomKey()
    {
        String key = "";
        final random = Random();
        for (int i = 0; i < KEY_LENGTH; i++)
        {
            int index = random.nextInt(KEY_LETTERS.length);
            key += KEY_LETTERS[index];
        }
        return key;
    }
}