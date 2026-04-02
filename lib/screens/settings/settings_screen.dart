import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/pro_service.dart';
import '../login/login_screen.dart';
import '../web_landing/web_landing_screen.dart'; // 🛡️ Changed to Web Landing Screen
import 'account_settings_screen.dart';
import '../../widgets/how_it_works_dialog.dart';
import '../../widgets/pro_paywall_sheet.dart'; 

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hapticsEnabled = true;
  bool _remindersEnabled = false;
  String _defaultSort = 'Name (A-Z)';

  final List<String> _sortOptions = [
    'Name (A-Z)',
    'Name (Z-A)',
    'Cards (High-Low)',
    'Cards (Low-High)'
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
      _remindersEnabled = prefs.getBool('reminders_enabled') ?? false;
      _defaultSort = prefs.getString('default_sort') ?? 'Name (A-Z)';
    });
  }

  Future<void> _saveBoolPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (_hapticsEnabled) HapticFeedback.lightImpact();
  }

  Future<void> _saveStringPreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    if (_hapticsEnabled) HapticFeedback.selectionClick();
  }

  Future<void> _toggleReminders(bool value) async {
    setState(() {
      _remindersEnabled = value;
    });
    await _saveBoolPreference('reminders_enabled', value);
    
    final notificationService = NotificationService();
    if (value) {
      await notificationService.scheduleDailyReminder();
    } else {
      await notificationService.cancelAllReminders();
    }
  }

  void _showFAQDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "FAQ & Help",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: isDark ? Colors.white54 : Colors.black54,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFAQItem(
                        context,
                        "How does the AI Energy work?",
                        "You get a maximum of 15 energy credits (30 for Pro users). Generating a deck costs 3 energy, while chatting costs 1. Energy resets daily!",
                      ),
                      const SizedBox(height: 20),
                      _buildFAQItem(
                        context,
                        "Do I need an internet connection?",
                        "You can study existing cards offline, but AI features and syncing require an active internet connection.",
                      ),
                      const SizedBox(height: 20),
                      _buildFAQItem(
                        context,
                        "How do I edit or delete a card?",
                        "Navigate to the deck view, locate the card, and tap the edit icon to modify or delete its content.",
                      ),
                      const SizedBox(height: 20),
                      _buildFAQItem(
                        context,
                        "Is my data safe?",
                        "Yes, your progress is encrypted and tied directly to your Google account for secure cross-device syncing.",
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4EFF).withOpacity(0.1),
                      foregroundColor: const Color(0xFF8B4EFF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Got it",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          answer,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  void _handleLogout(BuildContext context) async {
    if (_hapticsEnabled) HapticFeedback.mediumImpact();
    
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
        Navigator.of(context).pushAndRemoveUntil(
          // 🛡️ Web users log out directly to the Landing Page instead of the Login Screen
          MaterialPageRoute(builder: (context) => kIsWeb ? const WebLandingScreen() : const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
        title: Text("Settings", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          
          // 🛡️ REVENUECAT PRO BANNER
          AnimatedBuilder(
            animation: ProService(),
            builder: (context, _) {
              final isPro = ProService().isPro;
              return Container(
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  gradient: isPro 
                    ? const LinearGradient(colors: [Color(0xFFE841A1), Color(0xFF8B4EFF)])
                    : null,
                  color: isPro ? null : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: !isPro && isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: isPro ? null : () => ProPaywallSheet.show(context),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isPro ? Colors.white.withOpacity(0.2) : const Color(0xFFE841A1).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.workspace_premium_rounded, size: 28, color: isPro ? Colors.white : const Color(0xFFE841A1)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPro ? "MindFlash Pro Active" : "Upgrade to Pro",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isPro ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isPro ? "Thanks for your support! 💖" : "Double energy & no ads",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isPro ? Colors.white70 : (isDark ? Colors.white54 : Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isPro) Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white54 : Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          ),

          if (user != null) ...[
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
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    if (_hapticsEnabled) HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountSettingsScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFF5B4FE6).withOpacity(0.1),
                          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                          child: user.photoURL == null
                              ? const Icon(Icons.person, size: 32, color: Color(0xFF8B4EFF))
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName ?? 'MindFlash Student',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email ?? 'No email linked',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.white54 : Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],

          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "APP PREFERENCES",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                letterSpacing: 1.2,
              ),
            ),
          ),
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
            child: Column(
              children: [
                ValueListenableBuilder<ThemeMode>(
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
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF5B4FE6).withOpacity(0.2) : Colors.orange.withOpacity(0.2),
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
                        if (_hapticsEnabled) HapticFeedback.lightImpact();
                        themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                      },
                    );
                  },
                ),
                Divider(height: 1, indent: 60, color: isDark ? Colors.white12 : Colors.grey.shade200),
                SwitchListTile(
                  title: Text(
                    "Haptic Feedback",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    "Vibrations on taps and swipes",
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.vibration_rounded,
                      color: Color(0xFF00C853),
                    ),
                  ),
                  value: _hapticsEnabled,
                  activeColor: const Color(0xFF8B4EFF),
                  onChanged: (value) {
                    setState(() {
                      _hapticsEnabled = value;
                    });
                    _saveBoolPreference('haptics_enabled', value);
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "STUDY PREFERENCES",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                letterSpacing: 1.2,
              ),
            ),
          ),
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
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    "Daily Reminders",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    "Keep your study streak alive",
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9100).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFFFF9100),
                    ),
                  ),
                  value: _remindersEnabled,
                  activeColor: const Color(0xFF8B4EFF),
                  onChanged: (value) => _toggleReminders(value),
                ),
                Divider(height: 1, indent: 60, color: isDark ? Colors.white12 : Colors.grey.shade200),
                ListTile(
                  title: Text(
                    "Default Sort Order",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    "How decks appear on the dashboard",
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2979FF).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sort_rounded, color: Color(0xFF2979FF)),
                  ),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _defaultSort,
                      icon: Icon(Icons.expand_more, color: isDark ? Colors.white54 : Colors.grey.shade600),
                      dropdownColor: Theme.of(context).cardColor,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8B4EFF),
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _defaultSort = newValue;
                          });
                          _saveStringPreference('default_sort', newValue);
                        }
                      },
                      items: _sortOptions.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "HELP & SUPPORT",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                letterSpacing: 1.2,
              ),
            ),
          ),
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
            child: Column(
              children: [
                ListTile(
                  onTap: () {
                    if (_hapticsEnabled) HapticFeedback.lightImpact();
                    showDialog(
                      context: context,
                      builder: (context) => const HowItWorksDialog(),
                    );
                  },
                  title: Text(
                    "How It Works",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    "Replay the quick tutorial",
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded, color: Color(0xFF00C853)),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
                Divider(height: 1, indent: 60, color: isDark ? Colors.white12 : Colors.grey.shade200),
                ListTile(
                  onTap: () {
                    if (_hapticsEnabled) HapticFeedback.lightImpact();
                    _showFAQDialog();
                  },
                  title: Text(
                    "FAQ & Help",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    "Answers to common questions",
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2979FF).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.help_outline_rounded, color: Color(0xFF2979FF)),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
                Divider(height: 1, indent: 60, color: isDark ? Colors.white12 : Colors.grey.shade200),
                ListTile(
                  onTap: () async {
                    if (_hapticsEnabled) HapticFeedback.lightImpact();
                    final Uri emailUri = Uri.parse("mailto:support@mindflash.com?subject=MindFlash%20Feedback");
                    try {
                      if (!await launchUrl(emailUri)) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Could not open email client.")),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Could not open email client.")),
                        );
                      }
                    }
                  },
                  title: Text(
                    "Contact Us",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    "Send feedback or report a bug",
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9100).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mail_outline_rounded, color: Color(0xFFFF9100)),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "COMMUNITY & ABOUT",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                letterSpacing: 1.2,
              ),
            ),
          ),
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
            child: Column(
              children: [
                ListTile(
                  onTap: () async {
                    if (_hapticsEnabled) HapticFeedback.lightImpact();
                    try {
                      final InAppReview inAppReview = InAppReview.instance;
                      if (await inAppReview.isAvailable()) {
                        await inAppReview.requestReview();
                      } else {
                        await inAppReview.openStoreListing();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Could not open app store.")),
                        );
                      }
                    }
                  },
                  title: Text(
                    "Rate the App",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    "Love MindFlash? Let us know!",
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, color: Color(0xFFFFC107)),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
                Divider(height: 1, indent: 60, color: isDark ? Colors.white12 : Colors.grey.shade200),
                ListTile(
                  onTap: () async {
                    if (_hapticsEnabled) HapticFeedback.lightImpact();
                    try {
                      await Share.share(
                        'Check out MindFlash, an awesome AI-powered flashcard app! Download it today to master any subject.',
                        subject: 'Master anything with MindFlash!',
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Could not open share dialog.")),
                        );
                      }
                    }
                  },
                  title: Text(
                    "Share with Friends",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    "Help others master anything",
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE841A1).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share_rounded, color: Color(0xFFE841A1)),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "ACCOUNT",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                letterSpacing: 1.2,
              ),
            ),
          ),
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
          
          const SizedBox(height: 40),
          
          Center(
            child: Text(
              "MindFlash v1.0.0",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}