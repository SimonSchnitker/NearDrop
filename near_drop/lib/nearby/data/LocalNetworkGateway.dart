import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:near_drop/core/domain/entity/Device.dart';
import 'package:near_drop/core/domain/enums/DeviceType.dart';
import 'package:near_drop/core/domain/enums/OS.dart';
import 'package:near_drop/Runtime.dart';
import '../../core/Version.dart';
import 'event_args/NsdDeviceSpottedEventArgs.dart';

/// Diese Klasse implementiert den Datenaustausch via Sockets.
/// Sie fungiert sowohl als Server (lauscht auf Anfragen) als auch als Client (initiiert Anfragen).
class LocalNetworkGateway
{
    final Duration _timeoutDuration = const Duration(seconds: 4);

    ServerSocket? _serverSocket;
    final StreamController<Device> onDeviceResolved = StreamController<Device>.broadcast();

    /// Startet den lokalen Netzwerkserver und gibt den Port zurück, auf dem er lauscht.
    Future<int> startListening() async
    {
        if (_serverSocket != null)
        {
            print("Server lauscht bereits.");
            return _serverSocket?.port ?? -1;
        }

        try
        {
            _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
            print("Local Network Gateway lauscht auf Port ${_serverSocket!.port}");
            _serverSocket!.listen(_handleIncomingConnection);
            return _serverSocket!.port;
        }
        catch (e)
        {
            print("Fehler beim Starten des Local Network Gateway: $e");
        }

        return -1;
    }

    /// Stoppt den lokalen Netzwerkserver und bereinigt die Ressourcen.
    Future<void> stopListening() async
    {
        await _serverSocket?.close();
        _serverSocket = null;
    }

    /// Verarbeitet eine eingehende Verbindung von einem anderen Gerät, das einen Handshake initiiert.
    void _handleIncomingConnection(Socket client)
    {
        print("Eingehende Verbindung von ${client.remoteAddress.address}:${client.remotePort}");
        client.listen((Uint8List data) async
        {
            try
            {
                // Gerätedaten des anfragenden Geräts empfangen und dekodieren.
                String json = String.fromCharCodes(data);
                final Map<String, dynamic> deviceMap = jsonDecode(json);
                Device remoteDevice = _fromMap(deviceMap);

                // Eigene Gerätedaten als Antwort zurücksenden.
                final ownDeviceJson = _getOwnDeviceJson();
                client.write(ownDeviceJson);

                // Event auslösen, dass ein Gerät erfolgreich aufgelöst wurde.
                onDeviceResolved.add(remoteDevice);
                print("Gerät '${remoteDevice.firstname}' erfolgreich aufgelöst und eigene Daten gesendet.");
            }
            catch (e)
            {
                print("Fehler bei der Verarbeitung eingehender Daten: $e");
            }
            finally
            {
                await client.flush();
                client.destroy();
            }
        },
            onError: (error)
            {
                print("Socket-Fehler bei eingehender Verbindung: $error");
                client.destroy();
            },
            onDone: ()
            {
                client.destroy();
            },
        );
    }

    /// Initiiert einen Handshake mit einem via NSD entdeckten Gerät.
    /// **Diese Methode probiert alle IPv4-Adressen gleichzeitig.**
    Future<void> exchangeDeviceData(NsdDeviceSpottedEventArgs args) async
    {
        // In dieser Liste können InternetAddress-Objekte gespeichert werden und Hostnamen.
        List<dynamic> endPoints = [];
        if (args.host != null)
        {
            // Wenn ein Host angegeben ist, fügen wir ihn der Adressliste hinzu.
            endPoints.add(args.host!);
        }
        if (args.addresses != null && args.addresses!.isNotEmpty)
        {
            // Wenn Adressen angegeben sind, fügen wir sie der Adressliste hinzu.
            // Da wir nur auf IPv4-Adressen lauschen, filtern wir die Adressen.
            endPoints.addAll(args.addresses!.where((addr) => addr.type == InternetAddressType.IPv4));
        }

        if (endPoints.isEmpty)
        {
            print("Keine Endpunkte für Gerät ${args.nearbyUuid} gefunden.");
            return;
        }

        // Erstellt eine Liste von Verbindungsversuchen (Futures).
        final connectionFutures = endPoints.map((address) {
            return Socket.connect(address, args.port, timeout: _timeoutDuration);
        }).toList();

        Socket? socket;
        try
        {
            // Wartet auf den ersten Future, der erfolgreich abschließt.
            socket = await Future.any(connectionFutures);

            if (socket == null)
            {
                print("Keine Verbindung zu Gerät ${args.nearbyUuid} möglich.");
                return;
            }

            print("Erfolgreich verbunden mit ${socket.address}:${socket.port}.");

            // Eigene Gerätedaten senden.
            String ownJson = _getOwnDeviceJson();
            socket.write(ownJson);
            await socket.flush();

            // Auf die Antwort des anderen Geräts warten.
            final remoteData = await socket.first.timeout(_timeoutDuration);
            final remoteString = String.fromCharCodes(remoteData);
            final Map<String, dynamic> deviceMap = jsonDecode(remoteString);
            final remoteDevice = _fromMap(deviceMap);
            print("Antwort von '${remoteDevice.firstname}' erhalten.");

            // Event auslösen, dass ein Gerät erfolgreich aufgelöst wurde.
            onDeviceResolved.add(remoteDevice);
        }
        catch (e)
        {
            print("Konnte keine IPv4-Verbindung zu Gerät ${args.nearbyUuid} herstellen: $e");
        }
        finally
        {
            socket?.destroy();
        }
    }

    /// Serialisiert die eigenen Gerätedaten in JSON-Format.
    String _getOwnDeviceJson()
    {
        final deviceMap = {
            "firstname": Runtime.firstname,
            "name": Runtime.deviceName,
            "type": Runtime.deviceType.index,
            "os": Runtime.os.index,
            "version": Runtime.appVersion.toString(),
            "nearbyUuid": Runtime.nearbyUuid,
        };

        return jsonEncode(deviceMap);
    }

    Device _fromMap(Map<String, dynamic> json)
    {
        return Device(
            json["firstname"],
            json["name"],
            DeviceType.values[json["type"]],
            OS.values[json["os"]],
            Version.fromString(json["version"]),
            json["nearbyUuid"],
        );
    }
}
