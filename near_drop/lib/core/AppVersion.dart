/// Definiert den Aufbau einer App-Version.
/// Hiermit kann geprüft werden, ob Geräte miteinander kompatibel sind.
class AppVersion
{
  final int major;
  final int minor;
  final int patch;

  AppVersion(this.major, this.minor, this.patch);

  bool isCompatibleWith(AppVersion other) {
    // Major-Versionen müssen gleich sein, um kompatibel zu sein
    if (this.major != other.major) {
      return false;
    }
    // Minor- und Patch-Versionen können unterschiedlich sein, solange die Major-Version gleich ist
    return true;
  }

  @override
  String toString() {
    return '$major.$minor.$patch';
  }

  static AppVersion fromString(String version) {
    final parts = version.split('.');
    if (parts.length != 3) {
      throw FormatException('Invalid version format: $version');
    }
    return AppVersion(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}