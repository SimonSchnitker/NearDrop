import 'dart:io';
import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/Runtime.dart';
import 'package:near_drop/WelcomePage.dart';
import 'package:near_drop/auth/domain/AuthController.dart';
import 'package:near_drop/auth/presentation/pages/GuestSettingsPage.dart';
import 'package:near_drop/core/data/CoreGateway.dart';
import 'package:near_drop/core/presentation/UpdateRequiredPage.dart';
import 'package:near_drop/help/presentation/HelpPage.dart';
import 'package:near_drop/nearby/data/scan/ble/BleAdvertiser.dart';
import 'package:near_drop/nearby/data/scan/nsd/NsdAdvertiser.dart';
import 'package:near_drop/nearby/data/scan/nsd/NsdScanner.dart';
import 'package:near_drop/onboarding/presentation/OnboardingPage.dart';
import 'package:near_drop/settings/data/SettingsGateway.dart';
import 'package:near_drop/settings/domain/SettingsController.dart';
import 'package:near_drop/transport/data/SignalingGateway.dart';
import 'package:near_drop/transport/data/TransportGateway.dart';
import 'package:near_drop/transport/domain/SignalingController.dart';
import 'package:near_drop/transport/domain/TransportController.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'Routes.dart';
import 'auth/data/AuthGateway.dart';
import 'auth/presentation/pages/GuestLoginPage.dart';
import 'auth/presentation/pages/SavedUserDataPage.dart';
import 'core/domain/CoreController.dart';
import 'l10n/gen/app_localizations.dart';
import 'nearby/data/LocalNetworkGateway.dart';
import 'nearby/data/SupabaseDeviceGateway.dart';
import 'nearby/data/scan/ble/BleScanner.dart';
import 'nearby/domain/NearbyController.dart';
import 'nearby/presentation/pages/NearbyPage.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

void dprint(String message) {
    if (kDebugMode) {
        print(message);
    }
}

void main() async
{
    WidgetsFlutterBinding.ensureInitialized();

    // Fenster-Manager initialisieren, wenn auf Desktop-Plattformen
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
    {
        await windowManager.ensureInitialized();
        WindowOptions windowOptions = WindowOptions(
            title: Runtime.appName,
            minimumSize: Size(500, 500),
            size: Size(800, 650),
            center: true,
        );
        windowManager.waitUntilReadyToShow(windowOptions, () async {
            await windowManager.show();
            await windowManager.focus();
        });
    }

    await dotenv.load(fileName: ".env");

    // Neuen Foto-Picker unter Android aktivieren
    final ImagePickerPlatform imagePickerImplementation = ImagePickerPlatform.instance;
    if (imagePickerImplementation is ImagePickerAndroid)
    {
        imagePickerImplementation.useAndroidPhotoPicker = true;
    }

    await Runtime.initializeDeviceData();
    initializeDIContainer();

    await Supabase.initialize(
        url: "https://cjqgfozwhdrakszcnxkj.supabase.co",
        anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqcWdmb3p3aGRyYWtzemNueGtqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg5MzYzNDcsImV4cCI6MjA1NDUxMjM0N30.r2aXQ47Q6fl5suHv5tv6B-w1d52hyD-Pwi0Xi6ICpxk"
    );

    // Benutzerdaten laden
    if (Supabase.instance.client.auth.currentUser != null)
    {
        await KiwiContainer().resolve<AuthController>().loadUserData();
    }

    runApp(const MyApp());
}

void initializeDIContainer()
{
    final settingsGateway = SettingsGateway();
    final settingsController = SettingsController(settingsGateway);
    final authGateway = AuthGateway();
    final authController = AuthController(authGateway, settingsController);
    final bleScanner = BleScanner();
    final bleAdvertiser = BleAdvertiser();
    final nsdScanner = NsdScanner();
    final nsdAdvertiser = NsdAdvertiser();
    final supabaseDeviceGateway = SupabaseDeviceGateway();
    final localNetworkGateway = LocalNetworkGateway();
    final nearbyController = NearbyController(bleScanner, bleAdvertiser, nsdScanner, nsdAdvertiser, supabaseDeviceGateway, localNetworkGateway);
    final signalingGateway = SignalingGateway();
    final signalingController = SignalingController(signalingGateway);
    final transportGateway = TransportGateway();
    final transportController = TransportController(signalingController, transportGateway, settingsController);
    final coreGateway = CoreGateway();
    final coreController = CoreController(coreGateway, settingsController);

    KiwiContainer().registerInstance(settingsGateway);
    KiwiContainer().registerInstance(settingsController);
    KiwiContainer().registerInstance(authGateway);
    KiwiContainer().registerInstance(authController);
    KiwiContainer().registerInstance(bleScanner);
    KiwiContainer().registerInstance(bleAdvertiser);
    KiwiContainer().registerInstance(supabaseDeviceGateway);
    KiwiContainer().registerInstance(nearbyController);
    KiwiContainer().registerInstance(signalingGateway);
    KiwiContainer().registerInstance(signalingController);
    KiwiContainer().registerInstance(transportController);
    KiwiContainer().registerInstance(transportGateway);
    KiwiContainer().registerInstance(coreGateway);
    KiwiContainer().registerInstance(coreController);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
      return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: Runtime.appName,
                  localizationsDelegates: [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: [
                      Locale('en'), // English
                      Locale('de'), // Deutsch
                  ],
                  theme: ThemeData(
                      colorScheme: lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
                      //colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
                      pageTransitionsTheme: PageTransitionsTheme(
                          builders: {
                              TargetPlatform.android:
                                CupertinoPageTransitionsBuilder(),
                              TargetPlatform.windows:
                                FadeForwardsPageTransitionsBuilder(),
                          }
                      ),
                      tooltipTheme: TooltipThemeData(
                          waitDuration: Platform.isWindows || Platform.isMacOS || Platform.isLinux ? Duration(milliseconds: 800) : null,
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.inverseSurface,
                              borderRadius: BorderRadius.circular(4),
                          ),
                      ),
                      progressIndicatorTheme: ProgressIndicatorThemeData(
                          strokeCap: StrokeCap.round
                      )
                  ),
                  darkTheme: ThemeData(
                      colorScheme: darkDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
                      //colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
                      pageTransitionsTheme: PageTransitionsTheme(
                          builders: {
                              TargetPlatform.android:
                                CupertinoPageTransitionsBuilder(),
                              TargetPlatform.windows:
                                FadeForwardsPageTransitionsBuilder(),
                          }
                      ),
                      progressIndicatorTheme: ProgressIndicatorThemeData(
                          strokeCap: StrokeCap.round
                      ),
                      tooltipTheme: TooltipThemeData(
                          waitDuration: Platform.isWindows || Platform.isMacOS || Platform.isLinux ? Duration(milliseconds: 800) : null
                      )
                  ),
                  routes: {
                      Routes.welcome: (context) => WelcomePage(),
                      Routes.guestLogin: (context) => GuestLoginPage(),
                      Routes.nearby: (context) => NearbyPage(),
                      Routes.guestSettings: (context) => GuestSettingsPage(),
                      Routes.help: (context) => HelpPage(),
                      Routes.onboarding: (context) => OnboardingPage(),
                      Routes.savedUserData: (context) => SavedUserDataPage(),
                      Routes.requiredUpdate: (context) => UpdateRequiredPage(),
                  },
                  initialRoute: Supabase.instance.client.auth.currentUser == null ? Routes.welcome : Routes.nearby,
              );
          }
      );
  }
}