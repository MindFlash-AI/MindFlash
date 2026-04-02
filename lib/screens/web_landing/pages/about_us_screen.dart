import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/web_navigation_bar.dart'; // 🛡️ Import the sticky navbar
import '../login/web_login_screen.dart';
import '../../dashboard/dashboard_screen.dart';
import '../../../widgets/web_pro_gate.dart';
import '../../../constants.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // 🛡️ HCI FIX: Use Stack for Sticky Navigation so the NavBar stays at the top
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
            // --- Main Content ---
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: isMobile ? 32.0 : 64.0,
                        right: isMobile ? 32.0 : 64.0,
                        // Add top padding so the team header starts below the sticky navbar
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
                              "MEET THE TEAM",
                              style: TextStyle(color: Color(0xFF8B4EFF), fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "About Us",
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
                            "We are a passionate team of developers and educators dedicated to making learning faster, smarter, and more accessible through AI.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              height: 1.5,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 60),
                          
                          // --- Team Grid ---
                          Wrap(
                            spacing: 32,
                            runSpacing: 32,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildTeamMember(context, isDark, "Founder, Developer", "Chakinzo N. Sombito", "assets/sombito.png"),
                              _buildTeamMember(context, isDark, "Founder, Developer", "Matthew F. Simpas", "assets/simpas.jpg"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // --- Sticky Top Navigation Bar ---
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: WebNavBar(
                onActionTap: () => _launchWebApp(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🛡️ Consistent navigation logic for the Sign In / Dashboard button
  void _launchWebApp(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const WebProGate(child: DashboardScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WebLoginScreen()),
      );
    }
  }

  Widget _buildTeamMember(BuildContext context, bool isDark, String role, String name, String imageUrl) {
    final ImageProvider imageProvider = imageUrl.startsWith('http') 
        ? NetworkImage(imageUrl) 
        : AssetImage(imageUrl) as ImageProvider;

    return Container(
      width: 280,
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
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF8B4EFF), 
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B4EFF).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
              image: DecorationImage(
                image: imageProvider, 
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            role,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B4EFF),
            ),
          ),
        ],
      ),
    );
  }
}