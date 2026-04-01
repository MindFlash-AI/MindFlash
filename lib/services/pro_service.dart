import 'dart:io';
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
  static const bool _isMockMode = true;

  bool _isPro = false;
  
  /// Returns true if the user has an active MindFlash Pro subscription.
  bool get isPro => _isPro;

  /// Initializes the service and listens for Pro status.
  Future<void> init() async {
    // ==========================================
    // 🌐 WEB IMPLEMENTATION (FIRESTORE SYNC)
    // ==========================================
    if (kIsWeb) {
      // RevenueCat doesn't work on Web. Instead, we listen to the user's Auth state...
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          // ...and listen directly to their Firestore document!
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots()
              .listen((doc) {
            if (doc.exists) {
              final data = doc.data() ?? {};
              final entitlements = data['entitlements'] as Map<String, dynamic>? ?? {};
              
              // .containsKey works for both your manual "active" string and the Extension's map data
              final isCurrentlyPro = entitlements.containsKey(Constants.entitlementId);
              
              if (_isPro != isCurrentlyPro) {
                _isPro = isCurrentlyPro;
                notifyListeners();
              }
            }
          });
        } else {
          if (_isPro) {
            _isPro = false;
            notifyListeners();
          }
        }
      });
      return; // Exit init early so Web doesn't touch RevenueCat
    }


    // ==========================================
    // 📱 MOBILE IMPLEMENTATION (REVENUECAT)
    // ==========================================
    if (_isMockMode) {
      debugPrint("🛠️ PRO SERVICE: Running in MOCK MODE. RevenueCat initialization skipped.");
      return; 
    }

    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration? configuration;
    
    // Safely checking platform since we already returned early if kIsWeb
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(Constants.revenueCatGoogleApiKey);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(Constants.revenueCatAppleApiKey);
    }

    if (configuration != null) {
      await Purchases.configure(configuration);

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _updateProStatus(customerInfo);
      });

      try {
        CustomerInfo customerInfo = await Purchases.getCustomerInfo();
        _updateProStatus(customerInfo);
      } catch (e) {
        debugPrint("Error fetching RevenueCat customer info: $e");
      }
    }
  }

  /// Evaluates the CustomerInfo to determine if the user has the 'pro' entitlement.
  void _updateProStatus(CustomerInfo customerInfo) {
    final isCurrentlyPro = customerInfo.entitlements.all[Constants.entitlementId]?.isActive ?? false;
    
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
      _isPro = true;
      notifyListeners();
      return true;
    }

    try {
      Offerings offerings = await Purchases.getOfferings();
      
      if (offerings.current != null && offerings.current!.monthly != null) {
        PurchaseResult result = await Purchases.purchasePackage(offerings.current!.monthly!);
        _updateProStatus(result.customerInfo);
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
      _isPro = true; // Assuming they had it in mock mode
      notifyListeners();
      return true;
    }

    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _updateProStatus(customerInfo);
      return _isPro;
    } catch (e) {
      debugPrint("Restore error: $e");
      return false;
    }
  }
}