import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'pro_service.dart';
import '../constants/constants.dart';

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

  String? _lastUid;
  Stream<int>? _cachedEnergyStream;

  Stream<int> get energyStream {
    final currentUid = _uid;
    if (currentUid == null) return Stream.value(maxEnergy);
    
    if (_lastUid != currentUid) {
      _lastUid = currentUid;
      _cachedEnergyStream = _energyRef.snapshots().map((doc) {
        if (!doc.exists) return maxEnergy;
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return maxEnergy;
        
        final energy = (data['energy'] as num?)?.toInt() ?? maxEnergy;
        _currentEnergy = energy; 
        return energy;
      }).asBroadcastStream();
    }
    
    return _cachedEnergyStream!;
  }

  Future<void> init() async {
    if (_uid == null) return;

    try {
      // 🔒 SECURED: We completely removed all client-side writes to Firestore.
      // The frontend now simply reads the document to set initial state.
      // The backend (index.js) handles all daily resets and initializations.
      var doc = await _energyRef.get();
      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        _currentEnergy = (data['energy'] as num?)?.toInt() ?? maxEnergy;
      } else {
        _currentEnergy = maxEnergy;
      }
    } catch (e) {
      debugPrint("Error initializing EnergyService: $e");
    }
  }

  /// 🔥 SECURE REFILL LOGIC
  Future<void> refillEnergy() async {
    if (kIsWeb) {
      throw Exception("Energy refill is not allowed on web.");
    }

    if (_uid == null) {
      throw Exception("User not authenticated.");
    }

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
        throw Exception("Backend validation failed: ${response.body}");
      }
    } catch (e) {
      throw Exception("Refill failed: $e");
    }
  }
}