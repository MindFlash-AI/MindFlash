import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/constants.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'widgets/login_logo.dart';
import 'widgets/login_header.dart';
import 'widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleGoogleSignIn() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });

    final userCredential = await _authService.signInWithGoogle();

    if (userCredential != null && mounted) {
      HapticFeedback.mediumImpact();
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Optional: Show error snackbar if sign in fails/cancels
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Sign in canceled or failed. Please try again."),
            backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? Colors.redAccent.shade200 
                : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const LoginLogo(),
                const SizedBox(height: 24),
                const LoginHeader(),
                const Spacer(),
                GoogleSignInButton(
                  isLoading: _isLoading,
                  onTap: _handleGoogleSignIn,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}