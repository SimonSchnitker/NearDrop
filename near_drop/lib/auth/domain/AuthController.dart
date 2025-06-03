import 'package:near_drop/Runtime.dart';
import 'package:near_drop/auth/data/AuthGateway.dart';
import 'package:near_drop/settings/domain/SettingsController.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../settings/domain/Setting.dart';

/// Geschäftslogik zum Authentifizieren.
class AuthController
{
    final AuthGateway _authGateway;
    final SettingsController _settingsController;
    static final firstnameSetting = Setting("firstname", String);

    AuthController(this._authGateway, this._settingsController);

    /// Meldet einen anonymen Benutzer an.
    Future<AuthResponse> signInAnonymous(String firstname) async
    {
        AuthResponse response = await _authGateway.signInAnonymous();

        if (response.user == null)
        {
            throw Exception("Anmeldung fehlgeschlagen.");
        }

        await _settingsController.set(firstnameSetting, firstname);
        Runtime.firstname = firstname;
        return response;
    }

    /// Meldet den aktuellen Benutzer ab, löscht die Einstellungen und unsubscribt vom Realtime-Kanal.
    Future<void> signOutAndDeleteAccount() async
    {
        try
        {
            await _authGateway.signOut();
        }
        catch (e)
        {
            // Wenn der Benutzer keine Internetverbindung hat, kommt es hier zu einer Exception.
            // Ignorieren, da Supabase den Benutzer trotzdem abmeldet.
        }

        await Runtime.realtimeChannel.unsubscribe();
        await _settingsController.clear();
    }

    /// Lädt die eigenen Gerätedaten und aktualisiert ggf. die Nearby-UUID.
    Future<void> loadUserData() async
    {
        String? firstname = await _settingsController.get(firstnameSetting);
        if (firstname == null)
        {
            firstname = "???";
        }

        Runtime.firstname = firstname;
    }
}