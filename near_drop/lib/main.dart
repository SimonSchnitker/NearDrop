import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/Runtime.dart';
import 'package:near_drop/WelcomePage.dart';
import 'package:near_drop/auth/domain/AuthController.dart';
import 'package:near_drop/nearby/data/scan/ble/BleAdvertiser.dart';
import 'package:near_drop/settings/data/SettingsGateway.dart';
import 'package:near_drop/settings/domain/SettingsController.dart';
import 'package:near_drop/transport/data/SignalingGateway.dart';
import 'package:near_drop/transport/data/TransportGateway.dart';
import 'package:near_drop/transport/domain/SignalingController.dart';
import 'package:near_drop/transport/domain/TransportController.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Routes.dart';
import 'auth/data/AuthGateway.dart';
import 'auth/presentation/pages/GuestLoginPage.dart';
import 'nearby/data/NearbyGateway.dart';
import 'nearby/data/scan/ble/BleScanner.dart';
import 'nearby/domain/NearbyController.dart';
import 'nearby/presentation/pages/NearbyPage.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

void main() async
{
    WidgetsFlutterBinding.ensureInitialized();

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

    if (Supabase.instance.client.auth.currentUser != null)
    {
        try
        {
            await KiwiContainer().resolve<AuthController>().loadThisDevice();
        }
        catch (e)
        {
            //await Supabase.instance.client.auth.signOut();
            print("Error loading device data: $e");
            // TODO: Fehler-Page anzeigen
        }
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
    final nearbyGateway = NearbyGateway();
    final nearbyController = NearbyController(bleScanner, bleAdvertiser, nearbyGateway);
    final signalingGateway = SignalingGateway();
    final signalingController = SignalingController(signalingGateway);
    final transportGateway = TransportGateway();
    final transportController = TransportController(signalingController, transportGateway);

    KiwiContainer().registerInstance(settingsGateway);
    KiwiContainer().registerInstance(settingsController);
    KiwiContainer().registerInstance(authGateway);
    KiwiContainer().registerInstance(authController);
    KiwiContainer().registerInstance(bleScanner);
    KiwiContainer().registerInstance(bleAdvertiser);
    KiwiContainer().registerInstance(nearbyGateway);
    KiwiContainer().registerInstance(nearbyController);
    KiwiContainer().registerInstance(signalingGateway);
    KiwiContainer().registerInstance(signalingController);
    KiwiContainer().registerInstance(transportController);
    KiwiContainer().registerInstance(transportGateway);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Near Drop',
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
          tooltipTheme: TooltipThemeData(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.inverseSurface,
                  borderRadius: BorderRadius.circular(4),
              ),
          ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
      ),
      routes: {
          Routes.welcome: (context) => WelcomePage(),
          Routes.guestLogin: (context) => GuestLoginPage(),
          Routes.nearby: (context) => NearbyPage(),
      },
      initialRoute: Runtime.deviceDataLoaded ? Routes.nearby : Routes.welcome,
    );
  }
}