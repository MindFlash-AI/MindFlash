import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🛡️ Added Firestore import for GDPR wipe
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/card_storage_service.dart';
import '../../services/pro_service.dart';
import '../login/login_screen.dart';
import 'manage_subscription_screen.dart'; 
import 'dialogs/edit_profile_dialog.dart';
import 'dialogs/legal_document_dialog.dart';
import 'dialogs/delete_account_dialog.dart';
import 'account_settings_mobile.dart';
import 'account_settings_web.dart';
import '../../constants/legal_texts.dart';

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

    final newName = await EditProfileDialog.show(context, user.displayName ?? '');

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

  void _handleDeleteAccount() async {
    HapticFeedback.heavyImpact();

    final shouldDelete = await DeleteAccountDialog.show(context);

    if (shouldDelete != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = AuthService().currentUser;
      if (user != null) {
        // 🛡️ BUG FIX: Check if the login is recent BEFORE wiping the database.
        // Otherwise, data is wiped, but user.delete() fails with 'requires-recent-login', leaving an empty zombie account.
        final lastSignIn = user.metadata.lastSignInTime;
        if (lastSignIn == null || DateTime.now().difference(lastSignIn).inMinutes > 5) {
          throw FirebaseAuthException(
            code: 'requires-recent-login',
            message: 'Please log out and log back in to verify your identity before deleting your account.',
          );
        }

        // 🛡️ SECURITY FIX 1: GDPR-Compliant Account Deletion
        // Wipe all associated Firestore data before deleting the Auth Token
        final uid = user.uid;
        final firestore = FirebaseFirestore.instance;

        // 1. Wipe all Decks & their associated Cards
        final decks = await firestore.collection('users').doc(uid).collection('decks').get();
        final cardStorage = CardStorageService();
        for (var deck in decks.docs) {
          // 🛡️ BUG FIX: Use chunked batches to prevent rate limits and OOM crashes
          await cardStorage.deleteCardsByDeck(deck.id);
          await deck.reference.delete();
        }

        // 2 & 3. Wipe Study Pad Notes, Chat History & Energy Stats
        final notes = await firestore.collection('users').doc(uid).collection('notes').get();
        final chats = await firestore.collection('users').doc(uid).collection('chat').get();

        // 🚀 PERFORMANCE FIX: Use chunked WriteBatches instead of concurrent Future.wait network requests
        final allRefs = [
          ...notes.docs.map((d) => d.reference),
          ...chats.docs.map((d) => d.reference),
          firestore.collection('users').doc(uid).collection('stats').doc('energy'),
        ];
        
        // Firestore limits batches to 500 operations, chunking by 400 ensures safety
        for (var i = 0; i < allRefs.length; i += 400) {
          WriteBatch batch = firestore.batch();
          for (var ref in allRefs.skip(i).take(400)) { batch.delete(ref); }
          await batch.commit();
        }

        // 4. Delete the main User Document
        await firestore.collection('users').doc(uid).delete();

        // 5. FINALLY, delete the Auth token
        await user.delete();
        await AuthService().signOut();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occurred: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
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
                        backgroundColor: const Color(0xFF5B4FE6).withValues(alpha: 0.1),
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
                  border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
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
                      color: const Color(0xFF2979FF).withValues(alpha: 0.1),
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
                  border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () {
                    HapticFeedback.lightImpact();
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
                      color: const Color(0xFF8B4EFF).withValues(alpha: 0.1),
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
                  border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
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
                        LegalDocumentDialog.show(
                          context,
                          "Privacy Policy",
                          LegalTexts.privacyPolicy,
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
                          color: const Color(0xFF00C853).withValues(alpha: 0.1),
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
                        LegalDocumentDialog.show(
                          context,
                          "Terms of Service",
                          LegalTexts.termsOfService,
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
                          color: const Color(0xFFFF9100).withValues(alpha: 0.1),
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
                    color: Colors.redAccent.withValues(alpha: 0.8),
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // --- Delete Account Button ---
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: isDark ? 0.1 : 0.05),
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
                      color: Colors.redAccent.withValues(alpha: 0.1),
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
              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF8B4EFF),
                ),
              ),
            ),
        ],
      ),
    );
  }
}