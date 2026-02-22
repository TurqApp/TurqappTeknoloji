import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobKare extends StatefulWidget {
  const AdmobKare({super.key});

  static Future<void> warmupPool({int targetCount = 3}) {
    return _AdmobKareState.warmupPool(targetCount: targetCount);
  }

  @override
  State<AdmobKare> createState() => _AdmobKareState();
}

class _AdmobKareState extends State<AdmobKare> {
  static final List<BannerAd> _readyPool = <BannerAd>[];
  static int _loadingCount = 0;
  static const int _defaultWarmupCount = 3;

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isDisposed = false;
  bool _loadFailed = false;
  static const Duration _disposeDelay = Duration(milliseconds: 300);

  static String _resolveAdUnitId() {
    final bool isTestMode = kDebugMode;
    const String androidTestAdUnit = "ca-app-pub-3940256099942544/6300978111";
    const String iosTestAdUnit = "ca-app-pub-3940256099942544/2934735716";
    const String androidLiveAdUnit = "ca-app-pub-4558422035199571/2790203845";
    const String iosLiveAdUnit = "ca-app-pub-4558422035199571/8122867409";

    return isTestMode
        ? (Platform.isAndroid ? androidTestAdUnit : iosTestAdUnit)
        : (Platform.isAndroid ? androidLiveAdUnit : iosLiveAdUnit);
  }

  static Future<void> warmupPool({int targetCount = _defaultWarmupCount}) async {
    if (targetCount <= 0) return;

    final missing = targetCount - (_readyPool.length + _loadingCount);
    if (missing <= 0) return;

    for (int i = 0; i < missing; i++) {
      _loadingCount++;
      _createAndLoadBannerForPool();
    }
  }

  static void _createAndLoadBannerForPool() {
    final adUnitId = _resolveAdUnitId();
    final ad = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad loadedAd) {
          _loadingCount = (_loadingCount - 1).clamp(0, 999);
          if (_readyPool.length < 8) {
            _readyPool.add(loadedAd as BannerAd);
          } else {
            loadedAd.dispose();
          }
        },
        onAdFailedToLoad: (Ad failedAd, LoadAdError error) {
          _loadingCount = (_loadingCount - 1).clamp(0, 999);
          failedAd.dispose();
        },
      ),
    );

    ad.load();
  }

  BannerAd? _takePreloadedBanner() {
    if (_readyPool.isEmpty) return null;
    return _readyPool.removeAt(0);
  }

  @override
  void initState() {
    super.initState();
    _attachBannerOrLoad();
  }

  void _attachBannerOrLoad() {
    final pooled = _takePreloadedBanner();
    if (pooled != null) {
      _bannerAd = pooled;
      _isAdLoaded = true;
      _loadFailed = false;
      unawaited(warmupPool());
      if (mounted && !_isDisposed) {
        setState(() {});
      }
      return;
    }
    _loadBanner();
  }

  void _loadBanner() {
    // 🎯 Otomatik mod seçimi: Debug modda test reklamları, production'da gerçek reklamlar
    final String adUnitId = _resolveAdUnitId();

    if (kDebugMode) {
      print("🧪 AdmobKare: Test mode - Loading test ad: $adUnitId");
    }

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.mediumRectangle, // 300x250
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (kDebugMode) {
            print('✅ AdmobKare: Ad loaded successfully');
          }
          if (mounted && !_isDisposed) {
            setState(() {
              _isAdLoaded = true;
              _loadFailed = false;
            });
          }
          unawaited(warmupPool());
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          if (kDebugMode) {
            print('❌ AdmobKare: Ad failed to load - ${error.message}');
          }
          if (mounted && !_isDisposed) {
            setState(() {
              _loadFailed = true;
              _isAdLoaded = false;
            });
          }
          ad.dispose();
          _bannerAd = null;
        },
        onAdOpened: (Ad ad) {
          if (kDebugMode) {
            print('🔓 AdmobKare: Ad opened (user clicked)');
          }
        },
        onAdClosed: (Ad ad) {
          if (kDebugMode) {
            print('🔒 AdmobKare: Ad closed');
          }
        },
        onAdImpression: (Ad ad) {
          if (kDebugMode) {
            print('👁️ AdmobKare: Ad impression recorded');
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _isDisposed = true;
    final ad = _bannerAd;
    _isAdLoaded = false;
    _bannerAd = null;
    if (ad != null) {
      unawaited(Future<void>.delayed(_disposeDelay, () {
        try {
          ad.dispose();
        } catch (_) {}
      }));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reklam yüklenemedi veya dispose edildi
    if (_isDisposed || _loadFailed) {
      return const SizedBox.shrink();
    }

    // Reklam yüklenirken loading göster
    final ad = _bannerAd;
    if (!_isAdLoaded || ad == null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          height: 250,
          alignment: Alignment.center,
          child: const CupertinoActivityIndicator(),
        ),
      );
    }

    // 🎯 Reklam yüklendi - Tıklanabilir alan koruması ile göster
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Container(
          // 🛡️ Minimum boşluk - Yanlışlıkla tıklamayı azaltır
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "Reklam" etiketi (Google AdMob politikası gereği)
              const Padding(
                padding: EdgeInsets.only(top: 4.0, bottom: 2.0),
                child: Text(
                  'Reklam',
                  style: TextStyle(
                    fontSize: 10,
                    color: CupertinoColors.systemGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Reklam widget'ı
              SizedBox(
                width: ad.size.width.toDouble(),
                height: ad.size.height.toDouble(),
                child: AdWidget(
                  ad: ad,
                  key: ValueKey('admob_${ad.hashCode}'),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
