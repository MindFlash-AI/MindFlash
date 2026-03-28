import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Required for saving theme
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'screens/loading_screen/loading_screen.dart';
import 'constants.dart';  

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  
  // Only initialize AdMob if we are running on a mobile device, NOT the web.
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  // --- Load Saved Theme Preference ---
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false; // Default to light mode
  
  // Set the initial theme based on saved preference
  themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Add a listener to save the theme whenever it gets changed in Settings
  themeNotifier.addListener(() {
    prefs.setBool('isDarkMode', themeNotifier.value == ThemeMode.dark);
  });

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