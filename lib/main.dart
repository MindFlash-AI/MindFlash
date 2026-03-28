import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/loading_screen/loading_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MindFlash: AI Flashcards',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoadingScreen(),
    );
  }
}