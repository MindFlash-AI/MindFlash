import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🛡️ Added for HapticFeedback
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
                // --- Logo & Brand ---
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
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
                
                // --- Links (Hidden on Mobile) ---
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

                // --- Auth / Dashboard Actions ---
                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    final isLoggedIn = user != null;

                    if (isLoggedIn) {
                      // 🛡️ USER IS LOGGED IN: Show "Open App" and Profile Dropdown
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isMobile) ...[
                            ElevatedButton(
                              onPressed: onActionTap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).textTheme.bodyLarge?.color, 
                                foregroundColor: Theme.of(context).scaffoldBackgroundColor, 
                                elevation: 4,
                                shadowColor: Colors.black.withOpacity(0.2),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("Open App ⚡", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          _buildProfileDropdown(context, user, isDark),
                        ],
                      );
                    } else {
                      // 🛡️ USER IS LOGGED OUT: Show "Sign In"
                      return ElevatedButton(
                        onPressed: onActionTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).textTheme.bodyLarge?.color, 
                          foregroundColor: Theme.of(context).scaffoldBackgroundColor, 
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.2),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.login_rounded, size: 20),
                            SizedBox(width: 10),
                            Text("Sign In", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      );
                    }
                  }
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

  // 🛡️ Beautiful Avatar Dropdown for Account Management
  Widget _buildProfileDropdown(BuildContext context, User user, bool isDark) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 60),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05)),
      ),
      color: Theme.of(context).cardColor,
      elevation: 10,
      tooltip: "Account Menu",
      onSelected: (value) async {
        if (value == 'account') {
          // TODO: Navigate to Account Settings
        } else if (value == 'billing') {
          // TODO: Navigate to Stripe/Billing Portal
        } else if (value == 'signout') {
          // 🛡️ ADDED: Confirmation Modal before Sign Out
          HapticFeedback.mediumImpact();
          final shouldSignOut = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                "Sign Out",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                "Are you sure you want to sign out of MindFlash?",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("Sign Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );

          // Only proceed with sign out if the user confirmed
          if (shouldSignOut == true) {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false, // Just a header showing the user's email
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Signed in as",
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                user.email ?? "User",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'account',
          child: Row(
            children: [
              Icon(Icons.person_rounded, size: 20, color: isDark ? Colors.white70 : Colors.black87),
              const SizedBox(width: 12),
              const Text("My Account"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'billing',
          child: Row(
            children: [
              Icon(Icons.credit_card_rounded, size: 20, color: isDark ? Colors.white70 : Colors.black87),
              const SizedBox(width: 12),
              const Text("Manage Subscription"),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'signout',
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
              const SizedBox(width: 12),
              const Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF8B4EFF), width: 2),
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: isDark ? Colors.white12 : Colors.black12,
            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child: user.photoURL == null 
              ? Icon(Icons.person_rounded, color: isDark ? Colors.white70 : Colors.black54)
              : null,
          ),
        ),
      ),
    );
  }
}