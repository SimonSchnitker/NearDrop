/// Definiert den Aufbau einer Einstellung, die in den SharedPreferences gespeichert wird.
class Setting
{
    /// Der Schlüssel, unter dem die Einstellung gespeichert wird.
    final String key;

    /// Der Typ der Einstellung (z.B. String, int, bool).
    final Type type;

    Setting(this.key, this.type);
}