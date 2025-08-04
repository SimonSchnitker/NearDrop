import 'package:near_drop/core/Version.dart';

/// Repräsentiert die Antwort auf eine Anfrage nach der App-Version.
class AppVersionResponse
{
    Version latestVersion;
    Version requiredVersion;

    AppVersionResponse({
        required this.latestVersion,
        required this.requiredVersion,
    });
}