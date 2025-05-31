import 'package:near_drop/core/data/CoreGateway.dart';
import '../../Runtime.dart';
import '../../settings/domain/Setting.dart';
import '../../settings/domain/SettingsController.dart';

/// Steuert Core-Funktionen der App wie die Initialisierung der Nearby-UUID und des Realtime-Kanals.
/// Ohne diese Initialisierung kann die App nicht richtig funktionieren, da sie auf die Nearby-UUID und den Realtime-Kanal angewiesen ist.
class CoreController
{
    static const int UUID_VALIDITY_MINUTES = 10;

    final CoreGateway _coreGateway;
    final SettingsController _settingsController;

    CoreController(this._coreGateway, this._settingsController);

    static final nearbyUuidSetting = Setting("nearby_uuid", String);
    static final nearbyUuidCreationSetting = Setting("nearby_uuid_creation", String);

    /// Initialisiert die Nearby-UUID und den Realtime-Kanal.
    Future<void> inizialize() async
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

        bool realtimeChannelInitialized = await Runtime.initializeChannel();
        if (!realtimeChannelInitialized)
        {
            throw Exception("RealtimeChannel konnte nicht initialisiert werden.");
        }
    }

    /// Aktualisiert die Nearby-UUID in der Supabase-Datenbank und speichert sie in den SharedPreferences.
    Future<void> updateNearbyUuid() async
    {
        String uuid = await _coreGateway.updateNearbyUuid();
        await _settingsController.set(nearbyUuidSetting, uuid);
        await _settingsController.set(nearbyUuidCreationSetting, DateTime.now().toString());
        Runtime.nearbyUuid = uuid;
    }
}