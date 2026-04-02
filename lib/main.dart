import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; 
import 'firebase_options.dart';
import 'screens/loading_screen/loading_screen.dart';
import 'constants.dart';
import 'services/notification_service.dart';
import 'services/pro_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase FIRST
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Initialize App Check SECOND (Must be before ProService or any Firestore calls)
  if (!kIsWeb) {
    // UPDATED: Using the new provider parameters and classes
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode 
          ? AndroidDebugProvider() 
          : AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode 
          ? AppleDebugProvider() 
          : AppleDeviceCheckProvider(),
    );
  } else {
    // 🛡️ WEB FIX: Must use 'const' for the compiler to inject the value!
    const recaptchaKey = String.fromEnvironment('RECAPTCHA_KEY');
    
    if (recaptchaKey.isNotEmpty) {
      // UPDATED: Using providerWeb instead of webProvider
      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaV3Provider(recaptchaKey),
      );
    } else {
      debugPrint("Warning: RECAPTCHA_KEY is missing from build command");
    }
  }

  // 3. NOW initialize services that use Firestore
  await ProService().init();
  
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  // --- Load Saved Theme Preference ---
  final prefs = await SharedPreferences.getInstance();
  
  // Defaulting to Dark Mode for all new users
  final isDarkMode = prefs.getBool('isDarkMode') ?? true; 
  
  themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  themeNotifier.addListener(() {
    prefs.setBool('isDarkMode', themeNotifier.value == ThemeMode.dark);
  });

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(const MindFlashApp());
}

class MindFlashApp extends StatelessWidget {
  const MindFlashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'MindFlash',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: const LoadingScreen(),
        );
      },
    );
  }
}