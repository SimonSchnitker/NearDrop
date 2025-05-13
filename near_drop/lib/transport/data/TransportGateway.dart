import 'dart:convert';
import 'package:near_drop/transport/domain/enums/MimeTypeGroup.dart';
import 'package:near_drop/transport/domain/enums/SendRequestAnswer.dart';
import 'package:near_drop/transport/domain/models/RTCNetworkStream.dart';

class TransportGateway
{
    /// Schreibt eine Sendeanfrage an den Stream und wartet auf eine Antwort.
    Future<SendRequestAnswer> request(RTCNetworkStream stream, int filesCount, int totalSize, MimeTypeGroup mimeTypeGroup) async
    {
        Map<String, dynamic> payload = {
            "filesCount": filesCount,
            "totalSize": totalSize,
            "mimeTypes": mimeTypeGroup.name,
        };

        await stream.writeString(jsonEncode(payload));
        String response = await stream.readString();
        return SendRequestAnswer.values.byName(response);
    }
}