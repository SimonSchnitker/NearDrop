import 'package:near_drop/Runtime.dart';
import 'package:near_drop/auth/data/AuthGateway.dart';
import 'package:near_drop/settings/domain/SettingsController.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../settings/domain/Setting.dart';

/// Geschäftslogik zum Authentifizieren.
class AuthController
{
    static const int UUID_VALIDITY_MINUTES = 10;

    final AuthGateway _authGateway;
    final SettingsController _settingsController;

    static final firstnameSetting = Setting("firstname", String);
    static final nearbyUuidSetting = Setting("nearby_uuid", String);
    static final nearbyUuidCreationSetting = Setting("nearby_uuid_creation", String);

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
        await Runtime.realtimeChannel.unsubscribe();
        await _authGateway.signOut();
        await _settingsController.clear();
    }

    /// Lädt die eigenen Gerätedaten und aktualisiert ggf. die Nearby-UUID.
    Future<void> loadThisDevice() async
    {
        String? firstname = await _settingsController.get(firstnameSetting);
        if (firstname == null)
        {
            firstname = "???";
        }

        String? nearbyUuid = await _settingsController.get(nearbyUuidSetting);
        String? nearbyUuidCreation = await _settingsController.get(nearbyUuidCreationSetting);

        if (nearbyUuid == null || nearbyUuidCreation == null)
        {
            // Wenn die UUID-Daten nicht vorhanden sind, wird eine neue UUID generiert
            await updateNearbyUuid();
        }
        else
        {
            DateTime? creationDate = DateTime.tryParse(nearbyUuidCreation);

            if (creationDate == null || DateTime.now().difference(creationDate).inMinutes > UUID_VALIDITY_MINUTES)
            {
                // Wenn die UUID null oder älter als eine bestimmte Zeitspanne ist, wird eine neue UUID generiert
                await updateNearbyUuid();
            }
            else
            {
                Runtime.nearbyUuid = nearbyUuid;
            }
        }

        bool realtimeChannelInitialized = await Runtime.initializeChannel();
        if (!realtimeChannelInitialized)
        {
            throw Exception("RealtimeChannel konnte nicht initialisiert werden.");
        }

        Runtime.firstname = firstname;
        Runtime.deviceDataLoaded = true;
    }

    /// Aktualisiert die Nearby-UUID in der Supabase-Datenbank und speichert sie in den SharedPreferences.
    Future<void> updateNearbyUuid() async
    {
        String uuid = await _authGateway.updateNearbyUuid();
        await _settingsController.set(nearbyUuidSetting, uuid);
        await _settingsController.set(nearbyUuidCreationSetting, DateTime.now().toString());
        Runtime.nearbyUuid = uuid;
    }
}