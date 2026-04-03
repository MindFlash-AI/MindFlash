import 'dart:io';
import 'dart:async'; // 🛡️ Added to handle StreamSubscription
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';

/// A Singleton service that manages the RevenueCat integration for MindFlash Pro.
class ProService extends ChangeNotifier {
  // Singleton pattern setup
  static final ProService _instance = ProService._internal();
  factory ProService() => _instance;
  ProService._internal();

  // 🛠️ DEVELOPMENT BYPASS: Set this to 'true' to test the app without a Google Play/Apple Developer account.
  // 🛑 IMPORTANT: Change this to 'false' before publishing your app!
  static const bool _isMockMode = kDebugMode;

  bool _isPro = false;
  
  // Track platform statuses independently to avoid overwriting conflicts
  bool _isFirestorePro = false;
  bool _isRcPro = false;

  // 🛡️ FIX: Store the subscription so we can cleanly cancel it on logout
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  
  /// Returns true if the user has an active MindFlash Pro subscription.
  bool get isPro => _isPro;

  /// Initializes the service and listens for Pro status.
  Future<void> init() async {
    // ==========================================
    // 🌐 UNIVERSAL FIRESTORE SYNC (ALL PLATFORMS)
    // ==========================================
    // By running this on ALL platforms, a subscription bought on the Web 
    // will instantly unlock Pro on the user's Android/iOS app.
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // Cancel any previous listener before starting a new one
        _firestoreSubscription?.cancel();
        
        _firestoreSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((doc) {
          if (doc.exists) {
            final rawData = doc.data();
            
            // 🛡️ WEB FIX: Safely cast the dynamic JSON object to a strict Map
            final data = rawData != null ? Map<String, dynamic>.from(rawData as Map) : {};
            
            // 🛡️ WEB FIX: Safely cast the nested map
            final entitlementsRaw = data['entitlements'];
            final entitlements = entitlementsRaw != null 
                ? Map<String, dynamic>.from(entitlementsRaw as Map) 
                : {};
            
            _isFirestorePro = entitlements.containsKey(Constants.entitlementId);
            _evaluateCombinedStatus();
          }
        });
      } else {
        // 🛡️ CRITICAL FIX: Cancel the active listener when logging out!
        _firestoreSubscription?.cancel();
        
        _isFirestorePro = false;
        _evaluateCombinedStatus();
      }
    });

    // RevenueCat doesn't work on Web, so we exit here for web builds.
    if (kIsWeb) return; 

    // ==========================================
    // 📱 MOBILE IMPLEMENTATION (REVENUECAT)
    // ==========================================
    if (_isMockMode) {
      debugPrint("🛠️ PRO SERVICE: Running in MOCK MODE. RevenueCat initialization skipped.");
      return; 
    }

    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration? configuration;
    
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(Constants.revenueCatGoogleApiKey);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(Constants.revenueCatAppleApiKey);
    }

    if (configuration != null) {
      await Purchases.configure(configuration);

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _updateRcStatus(customerInfo);
      });

      try {
        CustomerInfo customerInfo = await Purchases.getCustomerInfo();
        _updateRcStatus(customerInfo);
      } catch (e) {
        debugPrint("Error fetching RevenueCat customer info: $e");
      }
    }
  }

  /// Updates the RevenueCat-specific status flag.
  void _updateRcStatus(CustomerInfo customerInfo) {
    _isRcPro = customerInfo.entitlements.all[Constants.entitlementId]?.isActive ?? false;
    _evaluateCombinedStatus();
  }

  /// Combines Web (Firestore) and Mobile (RevenueCat) statuses.
  /// If either platform says the user is Pro, we unlock the app.
  void _evaluateCombinedStatus() {
    final isCurrentlyPro = _isRcPro || _isFirestorePro;
    
    if (_isPro != isCurrentlyPro) {
      _isPro = isCurrentlyPro;
      notifyListeners();
    }
  }

  /// Initiates the purchase flow.
  Future<bool> purchasePro() async {
    if (kIsWeb) {
      debugPrint("Purchases cannot be made on the web.");
      return false;
    }

    if (_isMockMode) {
      debugPrint("🛠️ PRO SERVICE: Mocking successful purchase...");
      await Future.delayed(const Duration(seconds: 2)); // Simulate network request
      _isRcPro = true;
      _evaluateCombinedStatus();
      return true;
    }

    try {
      Offerings offerings = await Purchases.getOfferings();
      
      if (offerings.current != null && offerings.current!.monthly != null) {
        PurchaseResult result = await Purchases.purchasePackage(offerings.current!.monthly!);
        _updateRcStatus(result.customerInfo);
        return _isPro;
      } else {
        debugPrint("No current offering or monthly package found in RevenueCat.");
        return false;
      }
    } catch (e) {
      debugPrint("Purchase error: $e");
      return false;
    }
  }

  /// Restores previous purchases.
  Future<bool> restorePurchases() async {
    if (kIsWeb) {
      debugPrint("Restore purchases cannot be executed on the web.");
      return false;
    }

    if (_isMockMode) {
      debugPrint("🛠️ PRO SERVICE: Mocking successful restore...");
      await Future.delayed(const Duration(seconds: 1));
      _isRcPro = true; // Assuming they had it in mock mode
      _evaluateCombinedStatus();
      return true;
    }

    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _updateRcStatus(customerInfo);
      return _isPro;
    } catch (e) {
      debugPrint("Restore error: $e");
      return false;
    }
  }
}