import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../login/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _handleLogout(BuildContext context) async {
    HapticFeedback.mediumImpact();
    
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
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
            ),
            child: const Text("Sign Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await AuthService().signOut();
      
      if (context.mounted) {
        // Clear entire navigation stack and push to Login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        title: Text(
          "Settings",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Theme Toggle
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, child) {
                final isDarkMode = currentMode == ThemeMode.dark;
                return SwitchListTile(
                  title: Text(
                    "Dark Mode",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    "Toggle app appearance",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? const Color(0xFF5B4FE6).withOpacity(0.2) 
                          : Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: isDarkMode ? const Color(0xFF8B4EFF) : Colors.orange,
                    ),
                  ),
                  value: isDarkMode,
                  activeColor: const Color(0xFF8B4EFF),
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),

          // Logout Button
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              onTap: () => _handleLogout(context),
              title: const Text(
                "Sign Out",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
              subtitle: Text(
                "Disconnect your Google account",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}