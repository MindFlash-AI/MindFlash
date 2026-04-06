import 'dart:io';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'pro_service.dart'; // Added import for Pro status checking

class AdHelper {
  // ----------------------------------------------------------------------
  // 🛑 TOGGLE THIS TO 'false' ONLY WHEN READY TO PUBLISH TO PLAY STORE
  // Keeping it 'true' forces test ads even in 'flutter build apk' release.
  // ----------------------------------------------------------------------
  static const bool _useTestAds = true;

  // ======================================================================
  // BANNER ADS
  // ======================================================================

  static String get studyPadBannerAdUnitId {
    if (ProService().isPro || kIsWeb) return '';
    if (_useTestAds) return Platform.isAndroid ? 'ca-app-pub-3940256099942544/6300978111' : 'ca-app-pub-3940256099942544/2934735716';
    return Platform.isAndroid ? '<YOUR_ANDROID_STUDY_PAD_BANNER_ID>' : '<YOUR_IOS_STUDY_PAD_BANNER_ID>';
  }

  static String get chatBannerAdUnitId {
    if (ProService().isPro || kIsWeb) return '';
    if (_useTestAds) return Platform.isAndroid ? 'ca-app-pub-3940256099942544/6300978111' : 'ca-app-pub-3940256099942544/2934735716';
    return Platform.isAndroid ? '<YOUR_ANDROID_CHAT_BANNER_ID>' : '<YOUR_IOS_CHAT_BANNER_ID>';
  }

  static String get quizBannerAdUnitId {
    if (ProService().isPro || kIsWeb) return '';
    if (_useTestAds) return Platform.isAndroid ? 'ca-app-pub-3940256099942544/6300978111' : 'ca-app-pub-3940256099942544/2934735716';
    return Platform.isAndroid ? '<YOUR_ANDROID_QUIZ_BANNER_ID>' : '<YOUR_IOS_QUIZ_BANNER_ID>';
  }

  static String get reviewBannerAdUnitId {
    if (ProService().isPro || kIsWeb) return '';
    if (_useTestAds) return Platform.isAndroid ? 'ca-app-pub-3940256099942544/6300978111' : 'ca-app-pub-3940256099942544/2934735716';
    return Platform.isAndroid ? '<YOUR_ANDROID_REVIEW_BANNER_ID>' : '<YOUR_IOS_REVIEW_BANNER_ID>';
  }

  // ======================================================================
  // INTERSTITIAL ADS
  // ======================================================================

  static String get quizInterstitialAdUnitId {
    if (ProService().isPro || kIsWeb) return '';
    if (_useTestAds) return Platform.isAndroid ? 'ca-app-pub-3940256099942544/1033173712' : 'ca-app-pub-3940256099942544/4411468910';
    return Platform.isAndroid ? '<YOUR_ANDROID_QUIZ_INTERSTITIAL_ID>' : '<YOUR_IOS_QUIZ_INTERSTITIAL_ID>';
  }

  static String get reviewInterstitialAdUnitId {
    if (ProService().isPro || kIsWeb) return '';
    if (_useTestAds) return Platform.isAndroid ? 'ca-app-pub-3940256099942544/1033173712' : 'ca-app-pub-3940256099942544/4411468910';
    return Platform.isAndroid ? '<YOUR_ANDROID_REVIEW_INTERSTITIAL_ID>' : '<YOUR_IOS_REVIEW_INTERSTITIAL_ID>';
  }

  // ======================================================================
  // REWARDED ADS
  // ======================================================================

  static String get studyPadExportRewardedAdUnitId {
    if (kIsWeb) return '';
    if (_useTestAds) return Platform.isAndroid ? 'ca-app-pub-3940256099942544/5224354917' : 'ca-app-pub-3940256099942544/1712409664';
    return Platform.isAndroid ? '<YOUR_ANDROID_STUDY_PAD_EXPORT_REWARDED_ID>' : '<YOUR_IOS_STUDY_PAD_EXPORT_REWARDED_ID>';
  }

  static String get chatRefillRewardedAdUnitId {
    if (kIsWeb) return '';
    if (_useTestAds) return Platform.isAndroid ? 'ca-app-pub-3940256099942544/5224354917' : 'ca-app-pub-3940256099942544/1712409664';
    return Platform.isAndroid ? '<YOUR_ANDROID_CHAT_REFILL_REWARDED_ID>' : '<YOUR_IOS_CHAT_REFILL_REWARDED_ID>';
  }

  static String get createDeckRefillRewardedAdUnitId {
    if (kIsWeb) return '';
    if (_useTestAds) return Platform.isAndroid ? 'ca-app-pub-3940256099942544/5224354917' : 'ca-app-pub-3940256099942544/1712409664';
    return Platform.isAndroid ? '<YOUR_ANDROID_CREATE_DECK_REFILL_REWARDED_ID>' : '<YOUR_IOS_CREATE_DECK_REFILL_REWARDED_ID>';
  }

  static String get updateDeckRefillRewardedAdUnitId {
    if (kIsWeb) return '';
    if (_useTestAds) return Platform.isAndroid ? 'ca-app-pub-3940256099942544/5224354917' : 'ca-app-pub-3940256099942544/1712409664';
    return Platform.isAndroid ? '<YOUR_ANDROID_UPDATE_DECK_REFILL_REWARDED_ID>' : '<YOUR_IOS_UPDATE_DECK_REFILL_REWARDED_ID>';
  }

  static String get chatSponsoredMessageAdUnitId {
    if (kIsWeb) return '';
    if (_useTestAds) return Platform.isAndroid ? 'ca-app-pub-3940256099942544/5224354917' : 'ca-app-pub-3940256099942544/1712409664';
    return Platform.isAndroid ? '<YOUR_ANDROID_CHAT_SPONSORED_MSG_ID>' : '<YOUR_IOS_CHAT_SPONSORED_MSG_ID>';
  }

  static String get createDeckSponsoredMessageAdUnitId {
    if (kIsWeb) return '';
    if (_useTestAds) return Platform.isAndroid ? 'ca-app-pub-3940256099942544/5224354917' : 'ca-app-pub-3940256099942544/1712409664';
    return Platform.isAndroid ? '<YOUR_ANDROID_CREATE_DECK_SPONSORED_MSG_ID>' : '<YOUR_IOS_CREATE_DECK_SPONSORED_MSG_ID>';
  }

  static String get updateDeckSponsoredMessageAdUnitId {
    if (kIsWeb) return '';
    if (_useTestAds) return Platform.isAndroid ? 'ca-app-pub-3940256099942544/5224354917' : 'ca-app-pub-3940256099942544/1712409664';
    return Platform.isAndroid ? '<YOUR_ANDROID_UPDATE_DECK_SPONSORED_MSG_ID>' : '<YOUR_IOS_UPDATE_DECK_SPONSORED_MSG_ID>';
  }

  // ======================================================================
  // NATIVE ADS
  // ======================================================================

  static String get dashboardNativeAdUnitId {
    if (ProService().isPro || kIsWeb) return '';
    if (_useTestAds) return Platform.isAndroid ? 'ca-app-pub-3940256099942544/2247696110' : 'ca-app-pub-3940256099942544/3986624511';
    return Platform.isAndroid ? '<YOUR_ANDROID_DASHBOARD_NATIVE_ID>' : '<YOUR_IOS_DASHBOARD_NATIVE_ID>';
  }
}