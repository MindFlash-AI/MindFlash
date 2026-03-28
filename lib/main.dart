import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/loading_screen/loading_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'constants.dart';  

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  
  // Only initialize AdMob if we are running on a mobile device, NOT the web.
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

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