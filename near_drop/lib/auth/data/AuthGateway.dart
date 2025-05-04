import 'package:supabase_flutter/supabase_flutter.dart';

/// Stellt Methoden zum Authentifizieren mit Supabase bereit.
class AuthGateway
{
    /// Meldet einen anonymen Benutzer an.
    Future<AuthResponse> signInAnonymous() async
    {
        return await Supabase.instance.client.auth.signInAnonymously();
    }

    /// Legt eine neue UUID für den Benutzer in der Supabase-Datenbank an oder aktualisiert sie und gibt sie zurück.
    Future<String> updateNearbyUuid() async
    {
        return await Supabase.instance.client.rpc<String>("update_nearby_uuid");
    }
}