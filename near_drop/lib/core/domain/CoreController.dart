import 'package:flutter/material.dart';
import 'package:near_drop/core/data/CoreGateway.dart';
import 'package:near_drop/core/domain/entity/AppVersionResponse.dart';
import '../../Runtime.dart';
import '../../main.dart';
import '../../settings/domain/Setting.dart';
import '../../settings/domain/SettingsController.dart';
import '../Version.dart';
import '../data/dto/AppVersionDTO.dart';

/// Steuert Core-Funktionen der App wie die Initialisierung der Nearby-UUID und des Realtime-Kanals.
/// Ohne diese Initialisierung kann die App nicht richtig funktionieren, da sie auf die Nearby-UUID und den Realtime-Kanal angewiesen ist.
class CoreController
{
    static const int UUID_VALIDITY_MINUTES = 10;
    static const int CHANNEL_INITIALIZATION_RETRY_COUNT = 3;
    static const Duration CHANNEL_INITIALIZATION_RETRY_DELAY = Duration(seconds: 2);

    final CoreGateway _coreGateway;
    final SettingsController _settingsController;

    CoreController(this._coreGateway, this._settingsController);

    static final nearbyUuidSetting = Setting("nearby_uuid", String);
    static final nearbyUuidCreationSetting = Setting("nearby_uuid_creation", String);

    /// Initialisiert die Nearby-UUID und den Realtime-Kanal.
    Future<void> initialize() async
    {
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

        // Realtime-Kanal initialisieren
        // Dies wird mehrmals versucht, falls die Initialisierung fehlschlägt.
        for (int i = 0; i < CHANNEL_INITIALIZATION_RETRY_COUNT; i++)
        {
            try
            {
                bool initialized = await Runtime.initializeChannel();
                if (initialized)
                {
                    dprint("Realtime-Channel erfolgreich initialisiert.");
                    return;
                }
                else
                {
                    dprint("Realtime-Channel konnte nicht initialisiert werden. Versuch ${i + 1} von $CHANNEL_INITIALIZATION_RETRY_COUNT.");
                }
            }
            catch (e)
            {
                dprint("Realtime-Channel konnte nicht initialisiert werden. Versuch ${i + 1} von $CHANNEL_INITIALIZATION_RETRY_COUNT.");
            }

            await Future.delayed(CHANNEL_INITIALIZATION_RETRY_DELAY);
        }

        throw Exception("Realtime-Channel konnte nicht initialisiert werden. Bitte überprüfen Sie Ihre Internetverbindung.");
    }

    /// Aktualisiert die Nearby-UUID in der Supabase-Datenbank und speichert sie in den SharedPreferences.
    Future<void> updateNearbyUuid() async
    {
        String uuid = await _coreGateway.updateNearbyUuid();
        await _settingsController.set(nearbyUuidSetting, uuid);
        await _settingsController.set(nearbyUuidCreationSetting, DateTime.now().toString());
        Runtime.nearbyUuid = uuid;
    }

    /// Ruft die Versionsinformationen der App ab.
    Future<AppVersionResponse> getVersionInfo() async
    {
        AppVersionDTO dto = await _coreGateway.getVersionInfo();
        return AppVersionResponse(
            latestVersion: Version.fromString(dto.latestVersion),
            requiredVersion: Version.fromString(dto.requiredVersion),
        );
    }
}