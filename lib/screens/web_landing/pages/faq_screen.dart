import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/web_navigation_bar.dart'; 
import '../login/web_login_screen.dart';
import '../../dashboard/dashboard_screen.dart';
import '../../../widgets/web_pro_gate.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0B0714), const Color(0xFF1A1128)]
                : [const Color(0xFFFDF9FF), const Color(0xFFF3E8FF)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: isMobile ? 32.0 : 64.0,
                        right: isMobile ? 32.0 : 64.0,
                        top: isMobile ? 120.0 : 160.0, 
                        bottom: 80.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B4EFF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF8B4EFF).withOpacity(0.3)),
                            ),
                            child: const Text(
                              "SUPPORT",
                              style: TextStyle(color: Color(0xFF8B4EFF), fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Frequently Asked Questions",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 42 : 56,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              letterSpacing: -1.5,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 60),
                          
                          _buildFAQItem(context, isDark, "What is AI Energy?", "Energy is used to generate flashcards and chat with the AI. Free users get 15 energy daily, and Pro users get 30. Energy completely resets every 24 hours!"),
                          const SizedBox(height: 24),
                          _buildFAQItem(context, isDark, "How do I access the Web App?", "The web app is an exclusive feature for our Pro subscribers. Once you upgrade via the mobile app, you can log in on any desktop browser to create and study cards with a full keyboard."),
                          const SizedBox(height: 24),
                          _buildFAQItem(context, isDark, "Can I cancel my Pro subscription?", "Absolutely. You can cancel your subscription at any time through the Apple App Store or Google Play Store settings. You will retain Pro features until the end of your billing cycle."),
                          const SizedBox(height: 24),
                          _buildFAQItem(context, isDark, "Do I need an internet connection to study?", "You can review flashcards offline on the mobile app. However, generating new AI flashcards, syncing across devices, and accessing the web app requires an active internet connection."),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0, left: 0, right: 0,
              child: WebNavBar(onActionTap: () => _launchWebApp(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, bool isDark, String question, String answer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            answer,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _launchWebApp(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.push(context, PageRouteBuilder(pageBuilder: (c, a, s) => const WebProGate(child: DashboardScreen())));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const WebLoginScreen()));
    }
  }
}