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
        return response;
    }
}