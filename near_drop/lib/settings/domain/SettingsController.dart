import 'package:near_drop/settings/data/SettingsGateway.dart';
import 'Setting.dart';

/// Stellt Methoden bereit, um Einstellungen zu speichern, abzurufen und zu löschen.
class SettingsController
{
    final SettingsGateway _settingsGateway;

    SettingsController(this._settingsGateway);

    /// Speichert eine Einstellung in den SharedPreferences.
    Future<void> set(Setting setting, dynamic value) async
    {
        await _settingsGateway.set(setting, value);
    }

    /// Lädt eine Einstellung aus den SharedPreferences.
    Future<dynamic> get(Setting setting) async
    {
        return await _settingsGateway.get(setting);
    }

    /// Löscht alle Einstellungen aus den SharedPreferences.
    Future<void> clear() async
    {
        await _settingsGateway.clear();
    }
}