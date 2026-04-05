import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/settings_action_tile.dart';

class AccountSettingsMobile extends StatelessWidget {
  final User? user;
  final VoidCallback onEditProfile;
  final VoidCallback onManageSubscription;
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onTermsOfService;
  final VoidCallback onDataCompliance;
  final VoidCallback onDeleteAccount;

  const AccountSettingsMobile({
    super.key,
    required this.user,
    required this.onEditProfile,
    required this.onManageSubscription,
    required this.onPrivacyPolicy,
    required this.onTermsOfService,
    required this.onDataCompliance,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
        title: Text(
          "Account Settings",
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (user != null)
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF5B4FE6).withValues(alpha: 0.1),
                    backgroundImage: user!.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user!.photoURL == null ? const Icon(Icons.person, size: 40, color: Color(0xFF8B4EFF)) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user!.displayName ?? 'MindFlash Student',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user!.email ?? 'No email linked',
                    style: TextStyle(fontSize: 15, color: isDark ? Colors.white54 : Colors.grey.shade600),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "PROFILE",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.grey.shade500, letterSpacing: 1.2),
            ),
          ),
          SettingsActionTile(
            title: "Edit Display Name",
            subtitle: "Change how your name appears",
            icon: Icons.edit_rounded,
            iconColor: const Color(0xFF2979FF),
            onTap: onEditProfile,
          ),

          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "SUBSCRIPTION",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.grey.shade500, letterSpacing: 1.2),
            ),
          ),
          SettingsActionTile(
            title: "Manage Subscription",
            subtitle: "View or change your current plan",
            icon: Icons.star_rounded,
            iconColor: const Color(0xFF8B4EFF),
            onTap: onManageSubscription,
          ),

          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "LEGAL",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.grey.shade500, letterSpacing: 1.2),
            ),
          ),
          SettingsActionTile(
            title: "Privacy Policy",
            icon: Icons.privacy_tip_rounded,
            iconColor: const Color(0xFF00C853),
            onTap: onPrivacyPolicy,
          ),
          SettingsActionTile(
            title: "Terms of Service",
            icon: Icons.description_rounded,
            iconColor: const Color(0xFFFF9100),
            onTap: onTermsOfService,
          ),
          SettingsActionTile(
            title: "Data Compliance & GDPR",
            icon: Icons.security_rounded,
            iconColor: const Color(0xFF0284C7),
            onTap: onDataCompliance,
          ),

          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "DANGER ZONE",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent.withValues(alpha: 0.8), letterSpacing: 1.2),
            ),
          ),
          SettingsActionTile(
            title: "Delete Account",
            subtitle: "Permanently erase all your data",
            icon: Icons.delete_forever_rounded,
            iconColor: Colors.redAccent,
            onTap: onDeleteAccount,
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}