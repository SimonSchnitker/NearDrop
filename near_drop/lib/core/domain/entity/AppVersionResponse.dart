import 'package:near_drop/core/AppVersion.dart';

/// Repräsentiert die Antwort auf eine Anfrage nach der App-Version.
class AppVersionResponse
{
    AppVersion latestVersion;
    AppVersion requiredVersion;

    AppVersionResponse({
        required this.latestVersion,
        required this.requiredVersion,
    });
}