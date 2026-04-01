import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnergyService {
  static const int maxEnergy = 15;
  
  // 🛡️ BUG FIX 1: Make the service a Singleton so energy is perfectly synced across all screens
  static final EnergyService _instance = EnergyService._internal();
  factory EnergyService() => _instance;
  EnergyService._internal();

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

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      _currentEnergy = (data['energy'] as num?)?.toInt() ?? maxEnergy;

      final Timestamp? lastResetStamp = data['lastResetDate'] as Timestamp?;
      if (lastResetStamp != null) {
        final DateTime lastReset = lastResetStamp.toDate().toUtc();
        final DateTime now = DateTime.now().toUtc();
        
        if (lastReset.year != now.year ||
            lastReset.month != now.month ||
            lastReset.day != now.day) {
          _currentEnergy = maxEnergy; 
        }
      }

      _energyRef.set({
        'serverPing': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((e) {
        print("Server ping failed: $e");
      });
      
    } catch (e) {
      print("Error initializing Cloud Energy Service: $e");
    }
  }

  Future<void> deductEnergy({int amount = 1}) async {
    if (_currentEnergy >= amount) {
      _currentEnergy -= amount;
    } else {
      _currentEnergy = 0;
    }
  }

  Future<void> refillEnergy() async {
    int previousEnergy = _currentEnergy;
    _currentEnergy = maxEnergy; 

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
          _currentEnergy = previousEnergy;
          await init(); 
          throw Exception("Backend validation failed: ${response.body}");
        }
      } catch (e) {
        _currentEnergy = previousEnergy;
        await init();
        throw Exception("Network error during refill: $e");
      }
    }
  }
}