import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // 🛡️ ADDED: For launching external URLs

import '../widgets/web_navigation_bar.dart'; 
import '../widgets/web_footer.dart'; // 🛡️ Import the new reusable footer
import '../login/web_login_screen.dart';
import '../../dashboard/dashboard_screen.dart';
import '../../../widgets/web_pro_gate.dart';
import '../web_landing_screen.dart'; 

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SelectionArea(
        child: Container(
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
                child: Column(
                  children: [
                    // 1. The Origin Story
                    _buildMissionSection(context, isDark, isMobile),
                    const SizedBox(height: 80),
                    
                    // 2. Meet The Team
                    _buildTeamSection(context, isDark, isMobile),
                    const SizedBox(height: 120),
                    
                    // 3. Core Values
                    _buildCoreValuesSection(context, isDark, isMobile),
                    const SizedBox(height: 120),
                    
                    // 4. Bottom CTA
                    _buildBottomCTA(context, isDark, isMobile),
                    const SizedBox(height: 60),
                    
                    // 5. Footer (🛡️ Replaced with the global widget)
                    const WebFooter(),
                  ],
                ),
              ),
            ),

            // --- Sticky Top Navigation Bar ---
            Positioned(
              top: 0, left: 0, right: 0,
              child: WebNavBar(
                activePage: "About Us",
                onActionTap: () => _launchWebApp(context),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 1: THE ORIGIN STORY & MISSION
  // ===========================================================================
  Widget _buildMissionSection(BuildContext context, bool isDark, bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: EdgeInsets.only(
            left: isMobile ? 32.0 : 64.0,
            right: isMobile ? 32.0 : 64.0,
            top: isMobile ? 140.0 : 180.0, 
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4EFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF8B4EFF).withValues(alpha: 0.3)),
                ),
                child: const Text(
                  "OUR STORY",
                  style: TextStyle(color: Color(0xFF8B4EFF), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Empowering students\nthrough AI.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 42 : 64,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1.5,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                "Studying used to mean hours of highlighting, writing repetitive flashcards, and feeling overwhelmed by the sheer volume of material. We knew there had to be a better way.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 18 : 22,
                  height: 1.6,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "We built MindFlash to eliminate the busywork. By leveraging advanced AI and proven spaced-repetition algorithms, we are helping students spend less time preparing to study, and more time actually mastering the material.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  height: 1.6,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 2: MEET THE TEAM
  // ===========================================================================
  Widget _buildTeamSection(BuildContext context, bool isDark, bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 32.0 : 64.0),
          child: Column(
            children: [
              Text(
                "Meet the Founders",
                style: TextStyle(
                  fontSize: isMobile ? 32 : 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 60),
              Wrap(
                spacing: 40,
                runSpacing: 40,
                alignment: WrapAlignment.center,
                children: [
                  _buildTeamMember(
                    context, 
                    isDark, 
                    name: "Chakinzo N. Sombito", 
                    role: "Founder & Lead Developer", 
                    imageUrl: "assets/sombito.png",
                    funFact: "AI Enthusiast 🤖",
                    linkedinUrl: "https://www.linkedin.com/in/chakinzo-sombito-97940736a/",
                    githubUrl: "https://github.com/CSTwist",
                    email: "schakinzo@gmail.com",
                  ),
                  _buildTeamMember(
                    context, 
                    isDark, 
                    name: "Matthew F. Simpas", 
                    role: "Founder & Developer", 
                    imageUrl: "assets/simpas.jpg",
                    funFact: "UI/UX Obsessed 🎨",
                    linkedinUrl: "https://linkedin.com/in/MATTHEW_LINKEDIN_HERE",
                    githubUrl: "https://github.com/HewRMyFire",
                    email: "fmatthewsimpas@gmail.com",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamMember(BuildContext context, bool isDark, {
    required String name, 
    required String role, 
    required String imageUrl, 
    required String funFact,
    required String linkedinUrl,
    required String githubUrl,
    required String email,
  }) {
    return HoverLift(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  funFact,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF8B4EFF), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B4EFF).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
          child: ClipOval(
            child: imageUrl.startsWith('http')
                ? Image.network(imageUrl, fit: BoxFit.cover, gaplessPlayback: true)
                : Image.asset(imageUrl, fit: BoxFit.cover, gaplessPlayback: true),
          ),
            ),
            const SizedBox(height: 24),
            
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              role,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B4EFF),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(context, isDark, Icons.link_rounded, "LinkedIn", linkedinUrl),
                const SizedBox(width: 16),
                _buildSocialIcon(context, isDark, Icons.code_rounded, "GitHub", githubUrl),
                const SizedBox(width: 16),
                _buildSocialIcon(context, isDark, Icons.email_rounded, "Email", "mailto:$email"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(BuildContext context, bool isDark, IconData icon, String tooltip, String url) {
    return HoverScale(
      onTap: () async {
        final uri = Uri.parse(url);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint("Could not launch $url: $e");
        }
      },
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 3: CORE VALUES
  // ===========================================================================
  Widget _buildCoreValuesSection(BuildContext context, bool isDark, bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 32.0 : 64.0),
          child: Column(
            children: [
              Text(
                "Our Core Values",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 32 : 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 60),
              Wrap(
                spacing: 32,
                runSpacing: 32,
                alignment: WrapAlignment.center,
                children: [
                  HoverLift(child: _buildValueCard(context, isDark, "AI for Good", "Using technology to empower your learning and critical thinking, not replace it.", Icons.psychology_rounded)),
                  HoverLift(child: _buildValueCard(context, isDark, "Student-First", "Building tools that actually save you time, reduce stress, and boost your grades.", Icons.bolt_rounded)),
                  HoverLift(child: _buildValueCard(context, isDark, "Privacy Focused", "Your notes are your notes. We never train public models on your private study materials.", Icons.lock_rounded)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueCard(BuildContext context, bool isDark, String title, String description, IconData icon) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFE841A1), size: 40),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(fontSize: 15, height: 1.5, color: isDark ? Colors.white70 : Colors.black54),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 4: BOTTOM CTA
  // ===========================================================================
  Widget _buildBottomCTA(BuildContext context, bool isDark, bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 32.0 : 64.0),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 40 : 60),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B4EFF).withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "Ready to ace your next exam?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 32 : 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Join thousands of students learning faster with MindFlash.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 40),
                HoverScale(
                  onTap: () => _launchWebApp(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Text(
                      "Get Started for Free",
                      style: TextStyle(color: Color(0xFF8B4EFF), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
}