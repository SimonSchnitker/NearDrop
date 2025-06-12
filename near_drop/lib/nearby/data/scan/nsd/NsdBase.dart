import '../../../../Runtime.dart';

/// Basisklasse für die NSD-Implementierung (Network Service Discovery).
abstract class NsdBase
{
    static final String serviceType = "_${Runtime.appName.toLowerCase().replaceAll(" ", "")}._tcp";
}