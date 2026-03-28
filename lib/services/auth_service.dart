import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _googleInitialized = false;

  /// Ensure Google Sign-In is initialized once
  Future<void> _initGoogleSignIn() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleInitialized = true;
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _initGoogleSignIn();

      // Start Google authentication
      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();

      // Get ID Token
      final String? idToken = account.authentication.idToken;

      if (idToken == null) {
        throw Exception("Google ID Token is null");
      }

      // Get Access Token (NEW API way)
      final authClient = account.authorizationClient;
      final authResult =
          await authClient.authorizationForScopes(['email']);

      final String? accessToken = authResult?.accessToken;

      // Create Firebase credential
      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      // Sign in to Firebase
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      print("Google Sign-In Error (${e.code}): ${e.description}");
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
      await GoogleSignIn.instance.disconnect(); // revokes access
      await _auth.signOut();
    } catch (e) {
      print("Sign out error: $e");
    }
  }
}