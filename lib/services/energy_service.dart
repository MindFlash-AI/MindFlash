import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnergyService {
  static const int maxEnergy = 10;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _currentEnergy = maxEnergy;

  int get currentEnergy => _currentEnergy;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference get _energyRef {
    if (_uid == null) throw Exception("User not authenticated.");
    return _firestore.collection('users').doc(_uid).collection('stats').doc('energy');
  }

  Future<void> init() async {
    if (_uid == null) return;

    try {
      var doc = await _energyRef.get();

      if (!doc.exists) {
         _currentEnergy = maxEnergy;
         await _energyRef.set({
            'energy': maxEnergy,
            'lastResetDate': FieldValue.serverTimestamp(),
            'serverPing': FieldValue.serverTimestamp(),
         });
         return; 
      }

      await _energyRef.set({
        'serverPing': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      doc = await _energyRef.get();
      final data = doc.data() as Map<String, dynamic>?;

      if (data == null) return;

      final Timestamp? pingStamp = data['serverPing'] as Timestamp?;
      if (pingStamp == null) return;

      final DateTime trueServerTime = pingStamp.toDate();
      final Timestamp? lastResetStamp = data['lastResetDate'] as Timestamp?;
      
      bool isNewDay = true;

      if (lastResetStamp != null) {
        final DateTime lastReset = lastResetStamp.toDate();
        if (lastReset.year == trueServerTime.year &&
            lastReset.month == trueServerTime.month &&
            lastReset.day == trueServerTime.day) {
          isNewDay = false;
        }
      }

      if (isNewDay) {
        _currentEnergy = maxEnergy;
        await _energyRef.update({
          'energy': maxEnergy,
          'lastResetDate': pingStamp, 
        });
      } else {
        _currentEnergy = (data['energy'] as num?)?.toInt() ?? maxEnergy;
      }
      
    } catch (e) {
      print("Error initializing Cloud Energy Service: $e");
      _currentEnergy = maxEnergy; 
    }
  }

  Future<void> deductEnergy() async {
    if (_currentEnergy > 0) {
      _currentEnergy--;
      // Backend handles database deduction securely.
    }
  }

  /// Refills energy to max securely via the Node.js backend
  Future<void> refillEnergy() async {
    _currentEnergy = maxEnergy; // Update UI optimistically instantly

    if (_uid != null) {
      try {
        final String baseUrl = dotenv.env['BACKEND_URL']!.replaceAll('/generate-deck', '');
        final String refillUrl = '$baseUrl/refill-energy';

        final appCheckToken = await FirebaseAppCheck.instance.getToken();
        final idToken = await _auth.currentUser?.getIdToken();

        final response = await http.post(
          Uri.parse(refillUrl),
          headers: {
            'Content-Type': 'application/json',
            'X-Firebase-AppCheck': appCheckToken ?? '',
            'Authorization': 'Bearer ${idToken ?? ''}',
          },
        );

        if (response.statusCode != 200) {
          print("Failed to refill via backend: ${response.body}");
        }
      } catch (e) {
        print("Error calling refill endpoint: $e");
      }
    }
  }
}