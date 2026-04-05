import 'dart:io';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'pro_service.dart'; // Added import for Pro status checking

class AdHelper {
  // ----------------------------------------------------------------------
  // 🛑 TOGGLE THIS TO 'false' ONLY WHEN READY TO PUBLISH TO PLAY STORE
  // Keeping it 'true' forces test ads even in 'flutter build apk' release.
  // ----------------------------------------------------------------------
  static const bool _useTestAds = true;

  static String get bannerAdUnitId {
    // Guarded: Pro users do not see banner ads
    if (ProService().isPro) return '';
    
    if (kIsWeb) return ''; // Ads are currently disabled on web for stability
    
    if (_useTestAds) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111'; // Google Test Banner (Android)
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716'; // Google Test Banner (iOS)
      }
    } else {
      // ⚠️ REPLACE WITH YOUR REAL ADMOB BANNER IDs HERE
      if (Platform.isAndroid) {
        return '<YOUR_ANDROID_BANNER_AD_UNIT_ID>';
      } else if (Platform.isIOS) {
        return '<YOUR_IOS_BANNER_AD_UNIT_ID>';
      }
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    // Guarded: Pro users do not see interstitial ads
    if (ProService().isPro) return '';
    
    if (kIsWeb) return '';
    
    if (_useTestAds) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712'; // Google Test Interstitial (Android)
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910'; // Google Test Interstitial (iOS)
      }
    } else {
      // ⚠️ REPLACE WITH YOUR REAL ADMOB INTERSTITIAL IDs HERE
      if (Platform.isAndroid) {
        return '<YOUR_ANDROID_INTERSTITIAL_AD_UNIT_ID>';
      } else if (Platform.isIOS) {
        return '<YOUR_IOS_INTERSTITIAL_AD_UNIT_ID>';
      }
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get rewardedAdUnitId {
    // NOT GUARDED: Pro users still need rewarded ads to replenish their 30 energy
    if (kIsWeb) return '';
    
    if (_useTestAds) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/5224354917'; // Google Test Rewarded (Android)
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/1712409664'; // Google Test Rewarded (iOS)
      }
    } else {
      // ⚠️ REPLACE WITH YOUR REAL ADMOB REWARDED IDs HERE
      if (Platform.isAndroid) {
        return '<YOUR_ANDROID_REWARDED_AD_UNIT_ID>';
      } else if (Platform.isIOS) {
        return '<YOUR_IOS_REWARDED_AD_UNIT_ID>';
      }
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get nativeAdUnitId {
    // Guarded: Pro users do not see native ads
    if (ProService().isPro) return '';
    
    if (kIsWeb) return '';
    
    if (_useTestAds) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/2247696110'; // Google Test Native Advanced (Android)
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/3986624511'; // Google Test Native Advanced (iOS)
      }
    } else {
      // ⚠️ REPLACE WITH YOUR REAL ADMOB NATIVE IDs HERE
      if (Platform.isAndroid) {
        return '<YOUR_ANDROID_NATIVE_AD_UNIT_ID>';
      } else if (Platform.isIOS) {
        return '<YOUR_IOS_NATIVE_AD_UNIT_ID>';
      }
    }
    throw UnsupportedError('Unsupported platform');
  }
}