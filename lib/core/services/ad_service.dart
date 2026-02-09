import 'package:google_mobile_ads/google_mobile_ads.dart' as ads;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to manage Google AdMob ads
class AdService {
  // Test IDs from Google
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  // Production IDs - PLACEHOLDERS
  // Replace these with your real Ad Unit IDs from AdMob Console
  static const String prodBannerId = 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
  static const String prodInterstitialId = 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';

  static String get bannerAdUnitId => kDebugMode ? testBannerId : prodBannerId;
  static String get interstitialAdUnitId => kDebugMode ? testInterstitialId : prodInterstitialId;

  ads.InterstitialAd? _interstitialAd;
  int _interstitialRetryAttempts = 0;

  /// Load Interstitial Ad
  void loadInterstitialAd() {
    ads.InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const ads.AdRequest(),
      adLoadCallback: ads.InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialRetryAttempts = 0;
          debugPrint('AdService: Interstitial Ad loaded');
        },
        onAdFailedToLoad: (error) {
          _interstitialRetryAttempts++;
          _interstitialAd = null;
          debugPrint('AdService: Interstitial Ad failed to load - $error');
          if (_interstitialRetryAttempts <= 3) {
            loadInterstitialAd();
          }
        },
      ),
    );
  }

  /// Show Interstitial Ad if available and user is not Pro
  Future<void> showInterstitialAd(bool isPro) async {
    if (isPro) return;
    
    if (_interstitialAd == null) {
      loadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = ads.FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadInterstitialAd();
      },
    );

    await _interstitialAd!.show();
    _interstitialAd = null;
  }
}

final adServiceProvider = Provider((ref) => AdService());
