class Runtime
{
    static const int version = 1;
    static const Map<int, String> versionMap = {
        1: "1.0.0",
    };

    static String getVersionString()
    {
        if (versionMap.containsKey(version))
        {
            return versionMap[version]!;
        }
        else
        {
            return version.toString();
        }
    }
}