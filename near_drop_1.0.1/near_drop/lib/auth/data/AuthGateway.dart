import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Runtime.dart';

/// Stellt Methoden zum Authentifizieren mit Supabase bereit.
class AuthGateway
{
    /// Meldet einen anonymen Benutzer an.
    Future<AuthResponse> signInAnonymous() async
    {
        return await Supabase.instance.client.auth.signInAnonymously();
    }

    /// Meldet den aktuellen Benutzer ab.
    Future<void> signOut() async
    {
        return await Supabase.instance.client.auth.signOut();
    }

    /// Löscht den aktuellen Benutzer und meldet ihn ab.
    Future<void> deleteAccount() async
    {
        await Supabase.instance.client.rpc("delete_user");
        await Supabase.instance.client.auth.signOut();
    }

    /// Bestätigt die Zustimmung des Benutzers zu den Datenschutzbestimmungen und den Nutzungsbedingungen.
    Future<void> recordAllConsents() async
    {
        await Supabase.instance.client.rpc(
            "record_all_consents",
            params: {
                "p_privacy_version_id": Runtime.privacyPolicyVersion,
                "p_terms_version_id": Runtime.termsOfUseVersion,
            }
        );
    }

    Future<Map<String, dynamic>> getSavedUserData() async
    {
        return await Supabase.instance.client.rpc("get_user_data");
    }
}