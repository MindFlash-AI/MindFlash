import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/about_us_screen.dart'; 
import '../pages/features_screen.dart';
import '../pages/how_it_works_screen.dart';
import '../pages/pricing_screen.dart';
import '../pages/faq_screen.dart';

class WebNavBar extends StatelessWidget {
  final VoidCallback onActionTap;

  const WebNavBar({super.key, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16.0 : 40.0,
        vertical: 20.0, 
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0), 
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      // Note: Popping until first routes you back to the main Landing Screen
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10), 
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B4EFF).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "MindFlash",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (!isMobile)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNavLink(context, "Features", isDark, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const FeaturesScreen()));
                      }),
                      const SizedBox(width: 12),
                      _buildNavLink(context, "How it Works", isDark, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HowItWorksScreen()));
                      }),
                      const SizedBox(width: 12),
                      _buildNavLink(context, "Pricing", isDark, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const PricingScreen()));
                      }),
                      const SizedBox(width: 12),
                      _buildNavLink(context, "FAQ", isDark, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const FAQScreen()));
                      }),
                      const SizedBox(width: 12),
                      _buildNavLink(context, "About Us", isDark, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutUsScreen()));
                      }),
                    ],
                  ),

                ElevatedButton(
                  onPressed: onActionTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).textTheme.bodyLarge?.color, 
                    foregroundColor: Theme.of(context).scaffoldBackgroundColor, 
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      final isLoggedIn = snapshot.hasData && snapshot.data != null;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLoggedIn ? Icons.dashboard_rounded : Icons.login_rounded, 
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isLoggedIn ? "Dashboard" : "Sign In", 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavLink(BuildContext context, String title, bool isDark, {VoidCallback? onTap}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: isDark ? Colors.white70 : Colors.black87,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(title),
    );
  }
}