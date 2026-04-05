import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; 

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _googleInitialized = false;

  /// Ensure Google Sign-In is initialized once
  Future<void> _initGoogleSignIn() async {
    if (!_googleInitialized) {
      // 🛡️ WEB FIX: Extract to a separate 'const' variable
      const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb && webClientId.isNotEmpty ? webClientId : null,
      );
      _googleInitialized = true;
    }
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider webProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(webProvider);
      }

      await _initGoogleSignIn();

      GoogleSignInAccount? account;
      try {
        account = await GoogleSignIn.instance.authenticate();
      } on GoogleSignInException catch (e) {
        print("Google Sign-In canceled or failed (${e.code})");
        return null;
      }
      
      if (account == null) return null; 

      final GoogleSignInAuthentication googleAuth = await account.authentication;
      final authClient = account.authorizationClient;
      final authResult = await authClient.authorizationForScopes([
        'email',
        'profile',
      ]);

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: authResult?.accessToken,
      );

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

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _initGoogleSignIn();
        await GoogleSignIn.instance.disconnect(); 
      }
      await _auth.signOut();
    } catch (e) {
      print("Sign out error: $e");
    }
  }
}