import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'pro_service.dart';
import '../constants.dart';

class EnergyService {
  static final EnergyService _instance = EnergyService._internal();
  factory EnergyService() => _instance;
  EnergyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int get maxEnergy => ProService().isPro ? 30 : 15;

  int _currentEnergy = 15;
  int get currentEnergy => _currentEnergy;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference get _energyRef {
    if (_uid == null) {
      throw Exception("User not authenticated.");
    }
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('stats')
        .doc('energy');
  }

  static const String _backendUrl = String.fromEnvironment('BACKEND_URL');

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

      final rawData = doc.data();
      if (rawData == null) return;

      final data = Map<String, dynamic>.from(rawData as Map);

      _currentEnergy = (data['energy'] as num?)?.toInt() ?? maxEnergy;

      final Timestamp? lastResetStamp = data['lastResetDate'];

      if (lastResetStamp != null) {
        final now = DateTime.now().toUtc();
        final lastReset = lastResetStamp.toDate().toUtc();

        if (lastReset.year != now.year ||
            lastReset.month != now.month ||
            lastReset.day != now.day) {
          _currentEnergy = maxEnergy;

          await _energyRef.set({
            'energy': maxEnergy,
            'lastResetDate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      await _energyRef.set({
        'serverPing': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } catch (e) {
      print("Error initializing EnergyService: $e");
    }
  }

  Future<void> deductEnergy({int amount = 1}) async {
    _currentEnergy = (_currentEnergy >= amount)
        ? _currentEnergy - amount
        : 0;
  }

  /// 🔥 CLEAN REFILL LOGIC
  Future<void> refillEnergy() async {
    if (kIsWeb) {
      // Do NOT allow web to call backend
      throw Exception("Energy refill is not allowed on web.");
    }

    if (_uid == null) {
      throw Exception("User not authenticated.");
    }

    int previousEnergy = _currentEnergy;
    _currentEnergy = maxEnergy;

    try {
      final String baseUrl = _backendUrl.replaceAll('/generate-deck', '');
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
        _currentEnergy = previousEnergy;
        throw Exception("Backend validation failed: ${response.body}");
      }
    } catch (e) {
      _currentEnergy = previousEnergy;
      throw Exception("Refill failed: $e");
    }
  }
}