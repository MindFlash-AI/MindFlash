import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountSettingsWeb extends StatelessWidget {
  final User? user;
  final VoidCallback onEditProfile;
  final VoidCallback onManageSubscription;
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onTermsOfService;
  final VoidCallback onDeleteAccount;

  const AccountSettingsWeb({
    super.key,
    required this.user,
    required this.onEditProfile,
    required this.onManageSubscription,
    required this.onPrivacyPolicy,
    required this.onTermsOfService,
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. LEFT COLUMN: Master Profile Identity
                SizedBox(
                  width: 320,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF5B4FE6).withOpacity(0.1),
                          backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                          child: user?.photoURL == null ? const Icon(Icons.person, size: 50, color: Color(0xFF8B4EFF)) : null,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          user?.displayName ?? 'MindFlash Student',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.email ?? 'No email linked',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: isDark ? Colors.white54 : Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 40),
                
                // 2. RIGHT COLUMN: Actionable Settings List
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text("PROFILE SETTINGS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.grey.shade500, letterSpacing: 1.2)),
                      ),
                      _buildCard(
                        context, isDark,
                        child: ListTile(
                          onTap: onEditProfile,
                          title: Text("Edit Display Name", style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          subtitle: Text("Change how your name appears", style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                          leading: _buildIconBox(Icons.edit_rounded, const Color(0xFF2979FF)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        ),
                      ),

                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text("SUBSCRIPTION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.grey.shade500, letterSpacing: 1.2)),
                      ),
                      _buildCard(
                        context, isDark,
                        child: ListTile(
                          onTap: onManageSubscription,
                          title: Text("Manage Subscription", style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          subtitle: Text("View or change your current plan", style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                          leading: _buildIconBox(Icons.star_rounded, const Color(0xFF8B4EFF)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        ),
                      ),

                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text("LEGAL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.grey.shade500, letterSpacing: 1.2)),
                      ),
                      _buildCard(
                        context, isDark,
                        child: Column(
                          children: [
                            ListTile(
                              onTap: onPrivacyPolicy,
                              title: Text("Privacy Policy", style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                              leading: _buildIconBox(Icons.privacy_tip_rounded, const Color(0xFF00C853)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            ),
                            Divider(height: 1, indent: 60, color: isDark ? Colors.white12 : Colors.grey.shade200),
                            ListTile(
                              onTap: onTermsOfService,
                              title: Text("Terms of Service", style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                              leading: _buildIconBox(Icons.description_rounded, const Color(0xFFFF9100)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text("DANGER ZONE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent.withOpacity(0.8), letterSpacing: 1.2)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
                          boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: ListTile(
                          onTap: onDeleteAccount,
                          title: const Text("Delete Account", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                          subtitle: Text("Permanently erase all your data", style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                          leading: _buildIconBox(Icons.delete_forever_rounded, Colors.redAccent),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool isDark, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildIconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color),
    );
  }
}