import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:mutex/mutex.dart';
import '../../core/domain/entity/Device.dart';

/// Container für Geräte in der Nähe.
class NearbyDevicesContainer
{
    static final Duration _clearDevicesDelay = Duration(minutes: 5);
    static DateTime _appPaused = DateTime.now();

    static final StreamController<Device> onAdded = StreamController.broadcast();
    static final StreamController<Device> onRemoved = StreamController.broadcast();
    static final StreamController onCleared = StreamController.broadcast();

    static final List<Device> _nearbyDevices = [];
    static final _mutex = Mutex();

    /// Initialisiert einen Lifecycle-Listener, um die App-Pause zu überwachen.
    static void initLifecycleListener()
    {
        if (Platform.isAndroid || Platform.isIOS)
        {
            AppLifecycleListener(
                onInactive: () {
                    _appPaused = DateTime.now();
                },
                onResume: () {
                    // Wenn die App länger als _clearDevicesDelay pausiert war, leeren wir die Liste der Geräte.
                    if (DateTime.now().difference(_appPaused) > _clearDevicesDelay)
                    {
                        _nearbyDevices.clear();
                        onCleared.add(null);
                    }
                }
            );
        }
    }

    /// Gibt die Liste der Geräte zurück.
    static List<Device> getDevices()
    {
        return _nearbyDevices;
    }

    /// Fügt ein Gerät zur Liste hinzu, falls es noch nicht enthalten ist.
    static Future<void> addIfNotContains(Device device) async
    {
        await _mutex.protect(() async {
            if (_nearbyDevices.any((element) => element.nearbyUuid == device.nearbyUuid))
            {
                return;
            }

            _nearbyDevices.add(device);
            onAdded.add(device);
        });
    }

    /// Entfernt ein Gerät aus der Liste.
    static Future<void> remove(Device device) async
    {
        await _mutex.protect(() async {
            _nearbyDevices.remove(device);
            onRemoved.add(device);
        });
    }

    /// Entfernt ein Gerät aus der Liste anhand seiner UUID.
    static Future<void> removeByUuid(String uuid) async
    {
        await _mutex.protect(() async {
            Device? device = _nearbyDevices.firstWhereOrNull((device) => device.nearbyUuid == uuid);

            if (device != null)
            {
                _nearbyDevices.remove(device);
                onRemoved.add(device);
            }
        });
    }

    /// Ermittelt ein Gerät anhand seiner UUID.
    static Future<Device?> getByUuid(String id) async
    {
        return await _mutex.protect<Device?>(() async {
            return _nearbyDevices.firstWhereOrNull((device) => device.nearbyUuid == id);
        });
    }

    /// Prüft, ob ein Gerät mit der angegebenen UUID in der Liste enthalten ist.
    static Future<bool> containsUuid(String uuid) async
    {
        return await _mutex.protect<bool>(() async {
            return _nearbyDevices.any((device) => device.nearbyUuid == uuid);
        });
    }
}