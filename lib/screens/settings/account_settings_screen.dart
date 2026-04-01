import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/pro_service.dart';
import '../login/login_screen.dart';
import 'manage_subscription_screen.dart'; // Added the import for the new screen

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showEditProfileDialog() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    _nameController.text = user.displayName ?? '';

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Edit Profile",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: "Display Name",
              labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF8B4EFF), width: 2),
              ),
            ),
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _nameController.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4EFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != user.displayName) {
      setState(() {
        _isLoading = true;
      });

      try {
        await user.updateDisplayName(newName);
        await user.reload(); // Refresh the user data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile updated successfully!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to update profile. Please try again."),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showLegalDocument(String title, String content) {
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
                      title,
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
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                      height: 1.6,
                    ),
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
                      "Close",
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

  void _handleDeleteAccount() async {
    HapticFeedback.heavyImpact();

    // 1. Show strict confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 8),
            Text(
              "Delete Account",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "This action is permanent and cannot be undone. All your decks, flashcards, AI chat history, and pro status will be permanently erased.\n\nAre you absolutely sure?",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            height: 1.4,
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
            child: const Text("Delete Everything", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = AuthService().currentUser;
      if (user != null) {
        // 2. Attempt to delete the user from Firebase
        await user.delete();
        await AuthService().signOut();

        if (mounted) {
          // 3. Clear navigation stack and return to Login Screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Firebase requires a recent login to perform sensitive actions like deletion.
      // If the token is too old, it throws 'requires-recent-login'
      if (mounted) {
        String errorMessage = "Failed to delete account. Please try again later.";
        
        if (e.code == 'requires-recent-login') {
          errorMessage = "For your security, please log out and log back in before deleting your account.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Get the latest user data to display
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        title: Text(
          "Account Settings",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Display info for context
              if (user != null)
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFF5B4FE6).withOpacity(0.1),
                        backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                        child: user.photoURL == null
                            ? const Icon(Icons.person, size: 40, color: Color(0xFF8B4EFF))
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.displayName ?? 'MindFlash Student',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? 'No email linked',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  "PROFILE",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // --- Edit Profile Button ---
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
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showEditProfileDialog();
                  },
                  title: Text(
                    "Edit Display Name",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    "Change how your name appears",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2979FF).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, color: Color(0xFF2979FF)),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  "SUBSCRIPTION",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // --- Manage Subscription Button ---
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
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // 👉 This now correctly opens the new Manage Subscription Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageSubscriptionScreen()),
                    );
                  },
                  title: Text(
                    "Manage Subscription",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    "View or change your current plan",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B4EFF).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, color: Color(0xFF8B4EFF)),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  "LEGAL",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // --- Legal Links ---
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
                        HapticFeedback.lightImpact();
                        _showLegalDocument(
                          "Privacy Policy",
                          '''Last Updated: March 2026\n\nWelcome to MindFlash. Your privacy is critically important to us.\n\n1. Information We Collect\n• Account Data: When you sign in using Google, we collect your email address, display name, and profile picture.\n• App Usage Data: We store the flashcards, decks, and chat history you create to sync them across your devices.\n• Uploaded Documents: Documents you upload are temporarily processed by our servers to generate flashcards but are not permanently stored or used to train global AI models.\n• Device Data: We may collect anonymized device information and crash reports to improve app stability.\n\n2. Third-Party Services We Use\nWe use trusted third-party services that may collect data in accordance with their own privacy policies:\n• Google Cloud & Firebase (for database storage and secure authentication)\n• Google AdMob (to display advertisements to free users)\n• Google Gemini API (to generate AI flashcards and power the AI Tutor)\n• RevenueCat (to process and manage MindFlash Pro subscriptions)\n\n3. How We Use Your Data\nWe use your data solely to provide, maintain, and improve the MindFlash service. We do NOT sell your personal information to third parties.\n\n4. Your Rights & Data Deletion\nYou own your study materials. You can permanently delete your account, flashcards, and all associated data at any time using the "Delete Account" button in this app's settings.\n\n5. Children's Privacy\nMindFlash is intended for students and learners. We do not knowingly collect personal information from children under the age of 13 without parental consent.\n\nIf you have any questions about this Privacy Policy, please contact us via the Help & Support menu.''',
                        );
                      },
                      title: Text(
                        "Privacy Policy",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.privacy_tip_rounded, color: Color(0xFF00C853)),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    ),
                    Divider(height: 1, indent: 60, color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ListTile(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showLegalDocument(
                          "Terms of Service",
                          '''Last Updated: March 2026\n\nPlease read these Terms of Service carefully before using MindFlash.\n\n1. Acceptance of Terms\nBy accessing or using MindFlash, you agree to be bound by these Terms. If you disagree with any part of the terms, you do not have permission to access the service.\n\n2. AI Generation Disclaimer (Crucial)\nMindFlash uses artificial intelligence (Google Gemini) to generate study materials, answer questions, and summarize documents. \n• AI can make mistakes (hallucinations). \n• MindFlash does NOT guarantee the 100% accuracy, completeness, or reliability of generated content. \n• You are solely responsible for verifying the facts before relying on them for exams, medical, legal, or professional purposes. MindFlash is not liable for academic outcomes.\n\n3. User Content & Conduct\nYou are responsible for the documents and text you upload. You agree NOT to upload:\n• Copyrighted material you do not have the right to use.\n• Highly sensitive personal data (e.g., social security numbers, medical records).\n• Illegal, explicit, or harmful content.\n\n4. Subscriptions (MindFlash Pro)\nMindFlash offers auto-renewing subscriptions ("MindFlash Pro") that unlock premium features and remove ads. \n• Payment will be charged to your Apple or Google account at confirmation of purchase.\n• Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period.\n• You can manage or cancel your subscription directly in your device's App Store / Play Store settings.\n\n5. Termination\nWe reserve the right to terminate or suspend your account immediately, without prior notice, if you breach these Terms (e.g., attempting to hack the AI energy system or API).\n\n6. Changes to Terms\nWe reserve the right to modify these terms at any time. We will notify users of significant changes.''',
                        );
                      },
                      title: Text(
                        "Terms of Service",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9100).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.description_rounded, color: Color(0xFFFF9100)),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  "DANGER ZONE",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent.withOpacity(0.8),
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // --- Delete Account Button ---
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(isDark ? 0.1 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: _handleDeleteAccount,
                  title: const Text(
                    "Delete Account",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  subtitle: Text(
                    "Permanently erase all your data",
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
                    child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
              ),
            ],
          ),
          
          // Full-screen loading overlay while deleting/updating
          if (_isLoading)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF8B4EFF), // Default loading color instead of red
                ),
              ),
            ),
        ],
      ),
    );
  }
}