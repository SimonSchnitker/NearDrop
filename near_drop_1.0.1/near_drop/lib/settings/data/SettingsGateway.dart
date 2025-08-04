import 'package:shared_preferences/shared_preferences.dart';
import '../domain/Setting.dart';

/// Stellt Methoden bereit, um Key-Value-Paare in den SharedPreferences zu speichern und abzurufen.
class SettingsGateway
{
    static late final SharedPreferences _prefs;
    bool _isInitialized = false;

    /// Initialisiert die SharedPreferences.
    Future<void> _initialize() async
    {
        _prefs = await SharedPreferences.getInstance();
        _isInitialized = true;
    }

    /// Speichert eine Einstellung in den SharedPreferences.
    Future<bool> set(Setting setting, dynamic value) async
    {
        if (!_isInitialized)
        {
            await _initialize();
        }

        if (value.runtimeType == String)
        {
            return await _prefs.setString(setting.key, value);
        }
        else if (value.runtimeType == int)
        {
            return await _prefs.setInt(setting.key, value);
        }
        else if (value.runtimeType == bool)
        {
            return await _prefs.setBool(setting.key, value);
        }
        else if (value.runtimeType == double)
        {
            return await _prefs.setDouble(setting.key, value);
        }
        else if (value.runtimeType == List<String>)
        {
            return await _prefs.setStringList(setting.key, value);
        }

        return false;
    }

    /// Ruft einen Wert aus den SharedPreferences ab.
    Future<dynamic> get(Setting setting) async
    {
        if (!_isInitialized)
        {
            await _initialize();
        }

        if (setting.type == String)
        {
            return _prefs.getString(setting.key);
        }
        else if (setting.type == int)
        {
            return _prefs.getInt(setting.key);
        }
        else if (setting.type == bool)
        {
            return _prefs.getBool(setting.key);
        }
        else if (setting.type == double)
        {
            return _prefs.getDouble(setting.key);
        }
        else if (setting.type == List<String>)
        {
            return _prefs.getStringList(setting.key);
        }

        return null;
    }

    /// Löscht alle Einstellungen aus den SharedPreferences.
    Future<bool> clear() async
    {
        if (!_isInitialized)
        {
            await _initialize();
        }

        return await _prefs.clear();
    }
}