import 'package:supabase_flutter/supabase_flutter.dart';

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
}