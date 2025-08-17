/// Definiert den Aufbau einer App-Version.
/// Hiermit kann geprüft werden, ob Geräte miteinander kompatibel sind.
class Version
{
  final int major;
  final int minor;
  final int patch;

  Version(this.major, this.minor, this.patch);

  bool isCompatibleWith(Version other) {
    // Major-Versionen müssen gleich sein, um kompatibel zu sein
    if (this.major != other.major) {
      return false;
    }

    // Minor-Versionen müssen gleich sein, um kompatibel zu sein
    if (this.minor != other.minor) {
      return false;
    }

    // Patch-Versionen können unterschiedlich sein
    return true;
  }

  @override
  String toString() {
    return '$major.$minor.$patch';
  }

  bool operator >(Version other) {
    if (this.major != other.major) {
      return this.major > other.major;
    }
    if (this.minor != other.minor) {
      return this.minor > other.minor;
    }
    return this.patch > other.patch;
  }

    bool operator <(Version other) {
      if (this.major != other.major) {
        return this.major < other.major;
        }
      if (this.minor != other.minor) {
        return this.minor < other.minor;
        }
      return this.patch < other.patch;
    }

  static Version fromString(String version) {
    final parts = version.split('.');
    if (parts.length != 3) {
      throw FormatException('Invalid version format: $version');
    }
    return Version(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}