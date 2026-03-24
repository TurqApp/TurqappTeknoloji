import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:turqappv2/Core/Services/Ads/admob_unit_config_service.dart';

/// Tam ekran interstitial reklam gösterir
/// Debug modda otomatik olarak test reklamları kullanır
/// Production modda gerçek reklamları kullanır
Future<void> showUnskippableInterstitialAd() async {
  final bool isTestMode = kDebugMode;
  final adUnitId = AdmobUnitConfigService.ensure().nextInterstitialAdUnitId(
    isTestMode: isTestMode,
  );
  if (kDebugMode) {
    print(
      '${isTestMode ? '🧪' : '🚀'} InterstitialAd: ${isTestMode ? 'Test' : 'Production'} mode - Loading ad: $adUnitId',
    );
  }

  try {
    // Timeout ile reklam yükleme - 10 saniye içinde yüklenmezse iptal et
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          if (kDebugMode) {
            print('✅ InterstitialAd: Ad loaded successfully');
          }

          // Reklam davranışı
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              if (kDebugMode) {
                print('🔒 InterstitialAd: Ad dismissed by user');
              }
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (
              InterstitialAd ad,
              AdError error,
            ) {
              if (kDebugMode) {
                print('❌ InterstitialAd: Failed to show - ${error.message}');
              }
              ad.dispose();
            },
            onAdShowedFullScreenContent: (InterstitialAd ad) {
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

          // Reklamı göster
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (kDebugMode) {
            print('❌ InterstitialAd: Failed to load - ${error.message}');
            print('   Code: ${error.code}, Domain: ${error.domain}');
          }
        },
      ),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        if (kDebugMode) {
          print('⏱️ InterstitialAd: Load timeout after 10 seconds');
        }
        throw TimeoutException('InterstitialAd yükleme zaman aşımı');
      },
    );
  } catch (e) {
    if (kDebugMode) {
      print('❌ InterstitialAd: Exception occurred - $e');
    }
    // Sessizce başarısız ol - kullanıcı deneyimini bozmadan devam et
  }
}
