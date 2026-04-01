import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Required to read .env file

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _googleInitialized = false;

  /// Ensure Google Sign-In is initialized once using the new instance initialization
  Future<void> _initGoogleSignIn() async {
    if (!_googleInitialized) {
      // Initialize with your Web Client ID loaded securely from the .env file
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb ? dotenv.env['GOOGLE_WEB_CLIENT_ID'] : null,
      );
      _googleInitialized = true;
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google (Cross-Platform)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // ---------- WEB ----------
      // On Flutter Web, using Firebase's native popup is the most stable method.
      if (kIsWeb) {
        final GoogleAuthProvider webProvider = GoogleAuthProvider();
        // This opens the standard Google Sign-In popup safely in the browser
        return await _auth.signInWithPopup(webProvider);
      }

      // ---------- MOBILE (iOS & Android) ----------
      await _initGoogleSignIn();

      // Start Google authentication flow using the new authenticate() method
      GoogleSignInAccount? account;
      try {
        account = await GoogleSignIn.instance.authenticate();
      } on GoogleSignInException catch (e) {
        // Thrown if the user closes the modal or an error occurs during authentication
        print("Google Sign-In canceled or failed (${e.code})");
        return null;
      }
      
      // Safety check
      if (account == null) return null; 

      // 1. Obtain ID Token from the authentication request
      final GoogleSignInAuthentication googleAuth = await account.authentication;

      // 2. Obtain Access Token using the new authorization client
      final authClient = account.authorizationClient;
      final authResult = await authClient.authorizationForScopes([
        'email',
        'profile',
      ]);

      // 3. Create Firebase credential combining both
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: authResult?.accessToken,
      );

      // Sign in to Firebase
      return await _auth.signInWithCredential(credential);

    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error (${e.code}): ${e.message}");
      return null;
    } catch (e, stackTrace) {
      print("Unexpected Error: $e");
      print(stackTrace);
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Disconnect from Google (Only needed on mobile, Firebase handles Web)
      if (!kIsWeb) {
        await _initGoogleSignIn();
        await GoogleSignIn.instance.disconnect(); 
      }
      
      // Sign out of Firebase
      await _auth.signOut();
    } catch (e) {
      print("Sign out error: $e");
    }
  }
}