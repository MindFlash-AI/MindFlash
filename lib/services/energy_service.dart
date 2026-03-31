import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnergyService {
  static const int maxEnergy = 10; // Maximum daily energy allowance
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _currentEnergy = maxEnergy;

  // Getter for UI
  int get currentEnergy => _currentEnergy;

  // Safely get the current user's ID
  String? get _uid => _auth.currentUser?.uid;

  // Points to users/{uid}/stats/energy in Firestore
  DocumentReference get _energyRef {
    if (_uid == null) throw Exception("User not authenticated.");
    return _firestore.collection('users').doc(_uid).collection('stats').doc('energy');
  }

  /// Initializes the service, fetches true server time, and checks for daily resets.
  Future<void> init() async {
    if (_uid == null) return;

    try {
      // 1. Fetch the document FIRST to check if it's a brand new user
      var doc = await _energyRef.get();

      // If it's a brand new user, create the document perfectly formatted to pass security rules
      if (!doc.exists) {
         _currentEnergy = maxEnergy;
         await _energyRef.set({
            'energy': maxEnergy,
            'lastResetDate': FieldValue.serverTimestamp(),
            'serverPing': FieldValue.serverTimestamp(),
         });
         return; // Initialization complete!
      }

      // 2. THE PING: For existing users, force Firestore to record the absolute true time
      await _energyRef.set({
        'serverPing': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Fetch the document back to read that exact unhackable server time
      doc = await _energyRef.get();
      final data = doc.data() as Map<String, dynamic>?;

      if (data == null) return;

      final Timestamp? pingStamp = data['serverPing'] as Timestamp?;
      if (pingStamp == null) return;

      final DateTime trueServerTime = pingStamp.toDate();
      final Timestamp? lastResetStamp = data['lastResetDate'] as Timestamp?;
      
      bool isNewDay = true;

      // Compare the dates using the TRUE server time, not the device time!
      if (lastResetStamp != null) {
        final DateTime lastReset = lastResetStamp.toDate();
        
        // Check if the Year, Month, and Day exactly match
        if (lastReset.year == trueServerTime.year &&
            lastReset.month == trueServerTime.month &&
            lastReset.day == trueServerTime.day) {
          isNewDay = false; // It is still the same calendar day
        }
      }

      if (isNewDay) {
        // It's a brand new day according to Google's servers! Reset the energy.
        _currentEnergy = maxEnergy;
        await _energyRef.update({
          'energy': maxEnergy,
          'lastResetDate': pingStamp, 
        });
      } else {
        // Still the same day, fetch their saved cloud energy
        _currentEnergy = (data['energy'] as num?)?.toInt() ?? maxEnergy;
      }
      
    } catch (e) {
      print("Error initializing Cloud Energy Service: $e");
      _currentEnergy = maxEnergy; 
    }
  }

  /// Deducts 1 energy locally for UI speed. 
  /// The actual database deduction is securely handled by the Node.js backend now!
  Future<void> deductEnergy() async {
    if (_currentEnergy > 0) {
      _currentEnergy--;
      // REMOVED `_energyRef.set(...)` 
      // We don't write to Firebase here because the Node server already did it.
      // Doing it here caused a "Double Charge" that the Security Rules blocked!
    }
  }

  /// Refills energy to max (Used when watching an Ad)
  Future<void> refillEnergy() async {
    _currentEnergy = maxEnergy;
    if (_uid != null) {
      await _energyRef.set({
        'energy': _currentEnergy,
      }, SetOptions(merge: true));
    }
  }
}