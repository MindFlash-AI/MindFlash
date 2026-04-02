import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/web_navigation_bar.dart'; 
import '../login/web_login_screen.dart';
import '../../dashboard/dashboard_screen.dart';
import '../../../widgets/web_pro_gate.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

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
                    constraints: const BoxConstraints(maxWidth: 1200),
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
                              "SUPERCHARGE YOUR STUDYING",
                              style: TextStyle(color: Color(0xFF8B4EFF), fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Powerful Features",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 42 : 64,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              letterSpacing: -1.5,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Everything you need to master any topic, beautifully designed for web and mobile.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              height: 1.5,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 60),
                          
                          // Feature Grid
                          Wrap(
                            spacing: 32,
                            runSpacing: 32,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildFeatureCard(context, isDark, "AI Generation", "Upload your notes and let MindFlash generate perfect study decks in seconds.", Icons.auto_awesome_rounded),
                              _buildFeatureCard(context, isDark, "Spaced Repetition", "Our algorithm ensures you review cards exactly when you are about to forget them.", Icons.sync_rounded),
                              _buildFeatureCard(context, isDark, "Cross-Platform", "Study on your phone during your commute, and build decks on your desktop.", Icons.devices_rounded),
                              _buildFeatureCard(context, isDark, "Rich Formatting", "Support for bold text, lists, and deep formatting to make learning easier.", Icons.format_paint_rounded),
                            ],
                          ),
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

  Widget _buildFeatureCard(BuildContext context, bool isDark, String title, String description, IconData icon) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B4EFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF8B4EFF), size: 32),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black54,
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