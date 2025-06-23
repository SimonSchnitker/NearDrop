import 'dart:io';

import 'package:near_drop/core/data/dto/AppVersionDTO.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stellt Methoden zum Initialisieren der Core-Funktionalitäten der App bereit.
class CoreGateway
{
    /// Legt eine neue UUID für den Benutzer in der Supabase-Datenbank an oder aktualisiert sie und gibt sie zurück.
    Future<String> updateNearbyUuid() async
    {
        return await Supabase.instance.client.rpc<String>("update_nearby_uuid");
    }

    /// Ruft die Versionsinformationen der App von der Supabase-Datenbank ab.
    Future<AppVersionDTO> getVersionInfo() async
    {
        String os;
        if (Platform.isAndroid) {
            os = "android";
        } else if (Platform.isIOS) {
            os = "ios";
        } else if (Platform.isWindows) {
            os = "windows";
        } else if (Platform.isMacOS) {
            os = "macos";
        } else if (Platform.isLinux) {
            os = "linux";
        } else {
            throw UnsupportedError("Unsupported platform");
        }

        final response = await Supabase.instance.client
            .from("app_version")
            .select("latest, required")
            .eq("os", os)
            .single();

        return AppVersionDTO(
            latestVersion: response['latest'],
            requiredVersion: response['required'],
        );
    }
}