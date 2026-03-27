import 'dart:io';
import 'package:flutter/foundation.dart';

/// A helper class to manage AdMob Unit IDs.
/// It automatically uses Google's official test IDs during development
/// to prevent your AdMob account from being banned.
class AdHelper {
  // TODO: Replace these boolean toggles with environment variables in the future
  static const bool _isProduction = kReleaseMode;

  /// Returns the Banner Ad Unit ID
  static String get bannerAdUnitId {
    if (_isProduction) {
      // TODO: Replace with your actual AdMob PRODUCTION Banner ID when publishing
      return Platform.isAndroid 
          ? 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY' 
          : 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
    }
    
    // Official Google Test IDs for Banners
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// Returns the Interstitial Ad Unit ID
  static String get interstitialAdUnitId {
    if (_isProduction) {
      // TODO: Replace with your actual AdMob PRODUCTION Interstitial ID when publishing
      return Platform.isAndroid 
          ? 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY' 
          : 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
    }

    // Official Google Test IDs for Interstitials
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// Returns the Rewarded Ad Unit ID
  static String get rewardedAdUnitId {
    if (_isProduction) {
      // TODO: Replace with your actual AdMob PRODUCTION Rewarded ID when publishing
      return Platform.isAndroid 
          ? 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY' 
          : 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
    }

    // Official Google Test IDs for Rewarded Ads
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}