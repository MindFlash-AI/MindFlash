import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/gestures.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; 
// 🛡️ ADDED: Required for Quill Localization
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart'; 

import 'firebase_options.dart';
import 'screens/loading_screen/loading_screen.dart';
import 'constants/constants.dart';
import 'services/notification_service.dart';
import 'services/pro_service.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode 
          ? AndroidDebugProvider() 
          : AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode 
          ? AppleDebugProvider() 
          : AppleDeviceCheckProvider(),
    );
  } else {
    const recaptchaKey = String.fromEnvironment('RECAPTCHA_KEY');
    if (recaptchaKey.isNotEmpty) {
      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaV3Provider(recaptchaKey),
      );
    }
  }

  await ProService().init();
  
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  final prefs = await SharedPreferences.getInstance();
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
          scrollBehavior: AppScrollBehavior(),
          // 🛡️ FIX: Added Localization Delegates for Flutter Quill
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('zh', 'CN'), // Standard required by the package
          ],
          home: const LoadingScreen(),
        );
      },
    );
  }
}