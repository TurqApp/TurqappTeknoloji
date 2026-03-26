import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:turqappv2/Core/Services/Ads/admob_unit_config_service.dart';

const Duration _interstitialLoadTimeout = Duration(seconds: 4);
const Duration _interstitialLifecycleTimeout = Duration(seconds: 15);

/// Tam ekran interstitial reklam gösterir
/// Debug modda otomatik olarak test reklamları kullanır
/// Production modda gerçek reklamları kullanır
Future<bool> showUnskippableInterstitialAd() async {
  final bool isTestMode = kDebugMode;
  final config = ensureAdmobUnitConfigService();
  final availableIds = config.interstitialAdUnitIdsForCurrentPlatform(
    isTestMode: isTestMode,
  );
  final attemptedIds = <String>{};
  final maxAttempts = availableIds.length;

  for (var i = 0; i < maxAttempts; i++) {
    final adUnitId = config.nextInterstitialAdUnitId(isTestMode: isTestMode);
    if (!attemptedIds.add(adUnitId)) {
      continue;
    }
    if (kDebugMode) {
      print(
        '${isTestMode ? '🧪' : '🚀'} InterstitialAd: ${isTestMode ? 'Test' : 'Production'} mode - Loading ad: $adUnitId',
      );
    }
    final didShow = await _loadAndShowInterstitialAd(adUnitId);
    if (didShow) {
      return true;
    }
  }
  return false;
}

Future<bool> _loadAndShowInterstitialAd(String adUnitId) async {
  try {
    final completer = Completer<void>();
    var didShow = false;

    void completeOnce() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          if (kDebugMode) {
            print('✅ InterstitialAd: Ad loaded successfully');
          }

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              if (kDebugMode) {
                print('🔒 InterstitialAd: Ad dismissed by user');
              }
              ad.dispose();
              completeOnce();
            },
            onAdFailedToShowFullScreenContent: (
              InterstitialAd ad,
              AdError error,
            ) {
              if (kDebugMode) {
                print('❌ InterstitialAd: Failed to show - ${error.message}');
              }
              ad.dispose();
              completeOnce();
            },
            onAdShowedFullScreenContent: (InterstitialAd ad) {
              didShow = true;
              if (kDebugMode) {
                print('👁️ InterstitialAd: Ad showed full screen');
              }
            },
            onAdImpression: (InterstitialAd ad) {
              if (kDebugMode) {
                print('📊 InterstitialAd: Impression recorded');
              }
            },
          );

          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (kDebugMode) {
            print('❌ InterstitialAd: Failed to load - ${error.message}');
            print('   Code: ${error.code}, Domain: ${error.domain}');
          }
          completeOnce();
        },
      ),
    ).timeout(
      _interstitialLoadTimeout,
      onTimeout: () {
        if (kDebugMode) {
          print(
            '⏱️ InterstitialAd: Load timeout after ${_interstitialLoadTimeout.inSeconds} seconds',
          );
        }
        completeOnce();
        throw TimeoutException('InterstitialAd yükleme zaman aşımı');
      },
    );
    await completer.future.timeout(
      _interstitialLifecycleTimeout,
      onTimeout: () {
        completeOnce();
      },
    );
    return didShow;
  } catch (e) {
    if (kDebugMode) {
      print('❌ InterstitialAd: Exception occurred - $e');
    }
    return false;
  }
}
