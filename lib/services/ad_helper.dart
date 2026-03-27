import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {
  static const bool _isProduction = kReleaseMode;

  static String get bannerAdUnitId {
    if (!_isProduction) {
      // Test Banner ID
      return Platform.isAndroid 
          ? 'ca-app-pub-3940256099942544/6300978111' 
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    // Replace with your actual Production Banner ID
    return Platform.isAndroid ? 'YOUR_ANDROID_BANNER_ID' : 'YOUR_IOS_BANNER_ID';
  }

  static String get interstitialAdUnitId {
    if (!_isProduction) {
      // Test Interstitial ID
      return Platform.isAndroid 
          ? 'ca-app-pub-3940256099942544/1033173712' 
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    // Replace with your actual Production Interstitial ID
    return Platform.isAndroid ? 'YOUR_ANDROID_INTERSTITIAL_ID' : 'YOUR_IOS_INTERSTITIAL_ID';
  }

  static String get rewardedAdUnitId {
    if (!_isProduction) {
      // Test Rewarded ID
      return Platform.isAndroid 
          ? 'ca-app-pub-3940256099942544/5224354917' 
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    // Replace with your actual Production Rewarded ID
    return Platform.isAndroid ? 'YOUR_ANDROID_REWARDED_ID' : 'YOUR_IOS_REWARDED_ID';
  }
}