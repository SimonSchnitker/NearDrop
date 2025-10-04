import 'package:kiwi/kiwi.dart';
import 'package:near_drop/Runtime.dart';
import 'package:near_drop/auth/data/AuthGateway.dart';
import 'package:near_drop/auth/domain/model/Consent.dart';
import 'package:near_drop/auth/domain/model/UserData.dart';
import 'package:near_drop/auth/domain/model/UserSession.dart';
import 'package:near_drop/nearby/domain/NearbyController.dart';
import 'package:near_drop/settings/domain/SettingsController.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../settings/domain/Setting.dart';

/// Geschäftslogik zum Authentifizieren.
class AuthController
{
    final AuthGateway _authGateway;
    final SettingsController _settingsController;
    static final firstnameSetting = Setting("firstname", String);
    static final privacyPolicyVersionAcceptedSetting = Setting("privacyPolicyVersionAccepted", int);

    AuthController(this._authGateway, this._settingsController);

    /// Meldet einen anonymen Benutzer an.
    Future<AuthResponse> signInAnonymous(String firstname) async
    {
        AuthResponse response = await _authGateway.signInAnonymous();

        if (response.user == null)
        {
            throw Exception("Anmeldung fehlgeschlagen.");
        }

        try
        {
            // Eintragen in der Supabase-Datenbank, dass der Benutzer alle Einwilligungen gegeben hat.
            await _authGateway.recordAllConsents();
            await _settingsController.set(privacyPolicyVersionAcceptedSetting, Runtime.privacyPolicyVersion);
        }
        catch (e)
        {
            // Sollte ein Fehler beim Aufzeichnen der Einwilligungen auftreten, wird der Benutzer wieder gelöscht.
            await _authGateway.deleteAccount();
            throw Exception("Fehler beim Aufzeichnen der Einwilligungen: $e");
        }

        await _settingsController.set(firstnameSetting, firstname);
        Runtime.firstname = firstname;
        return response;
    }

    Future<void> recordNewestPrivacyConsent() async
    {
        await _authGateway.recordAllConsents();
    }

    /// Meldet den aktuellen Benutzer ab, löscht die Einstellungen und unsubscribt vom Realtime-Kanal.
    Future<void> signOutAndDeleteAccount() async
    {
        try
        {
            await _authGateway.deleteAccount();
        }
        catch (e)
        {
            // Fehler ignorieren
        }

        try
        {
            await _settingsController.clear();
            await Runtime.realtimeChannel.unsubscribe();
            await KiwiContainer().resolve<NearbyController>().stopNsdServices();
            await KiwiContainer().resolve<NearbyController>().stopBleScanner();
            await KiwiContainer().resolve<NearbyController>().stopBleAdvertiser();
        }
        catch (e)
        {
            // Fehler beim Unsubscribe oder Löschen der Einstellungen ignorieren
            // (z.B. wenn der Kanal bereits unsubscribed ist oder die Einstellungen leer sind)
        }
    }

    /// Lädt die eigenen Gerätedaten und aktualisiert ggf. die Nearby-UUID.
    Future<void> loadUserData() async
    {
        String? firstname = await _settingsController.get(firstnameSetting);
        if (firstname == null)
        {
            firstname = "???";
        }
        int? acceptedVersion = await _settingsController.get(privacyPolicyVersionAcceptedSetting);

        Runtime.firstname = firstname;
        Runtime.hasNewestPrivacyPolicyAccepted = acceptedVersion != null && acceptedVersion >= Runtime.privacyPolicyVersion;
    }

    /// Ruft alle Daten des Benutzers ab, die auf dem Supabase-Server gespeichert sind.
    Future<UserData> getSavedUserData() async
    {
        final data = await _authGateway.getSavedUserData();

        List<UserSession> sessions = [];
        for (var session in data['sessions'] as List<dynamic>)
        {
            sessions.add(UserSession(id: session["id"], ipAddress: session["ip"]));
        }

        List<Consent> privacyPolicyConsents = [];
        for (var consent in data['privacy_consents'] as List<dynamic>)
        {
            privacyPolicyConsents.add(Consent(
                version: consent["version"],
                acceptedAt: DateTime.parse(consent["accepted_at"]),
            ));
        }

        List<Consent> termsOfUseConsents = [];
        for (var consent in data['terms_consents'] as List<dynamic>)
        {
            termsOfUseConsents.add(Consent(
                version: consent["version"],
                acceptedAt: DateTime.parse(consent["accepted_at"]),
            ));
        }

        return UserData(
            userId: Supabase.instance.client.auth.currentUser!.id,
            createdAt: DateTime.parse(Supabase.instance.client.auth.currentUser!.createdAt),
            updatedAt: DateTime.tryParse(Supabase.instance.client.auth.currentUser!.updatedAt ?? ""),
            lastSignInAt: DateTime.parse(Supabase.instance.client.auth.currentUser!.lastSignInAt ?? ""),
            sessions: sessions,
            privacyPolicyConsents: privacyPolicyConsents,
            termsOfUseConsents: termsOfUseConsents
        );
    }
}