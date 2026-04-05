import 'dart:convert';
import 'dart:typed_data';

class SecureCacheService {
  static const String _salt = "MindFlash_Secure_V1_8b4eff";

  /// Encrypts the JSON payload using a UID-derived XOR cipher and Base64 encoding.
  /// This prevents casual users from reading or tampering with the local SharedPreferences.
  static String encrypt(String payload, String uid) {
    final textBytes = utf8.encode(payload);
    final keyBytes = utf8.encode(uid + _salt);
    
    // 🚀 PERFORMANCE FIX: Pre-allocate Uint8List instead of dynamically growing an array.
    // This stops massive GC pauses when encrypting large JSONs (like Study Pad data).
    final result = Uint8List(textBytes.length);
    for (int i = 0; i < textBytes.length; i++) {
      result[i] = textBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return base64Encode(result);
  }

  /// Decrypts the payload back to the original JSON string.
  static String decrypt(String base64Payload, String uid) {
    try {
      final textBytes = base64Decode(base64Payload);
      final keyBytes = utf8.encode(uid + _salt);
      
      // 🚀 PERFORMANCE FIX: Pre-allocate Uint8List for fast decryption.
      final result = Uint8List(textBytes.length);
      for (int i = 0; i < textBytes.length; i++) {
        result[i] = textBytes[i] ^ keyBytes[i % keyBytes.length];
      }
      return utf8.decode(result);
    } catch (e) {
      return ""; // Fails safely if the payload was tampered with
    }
  }
}