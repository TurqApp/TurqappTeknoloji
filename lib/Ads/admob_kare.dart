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
  static const int _maxPoolSize = 8;
  static const bool _renderLiveAdsInDebug = bool.fromEnvironment(
    'DEBUG_RENDER_ADMOB',
    defaultValue: false,
  );

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isDisposed = false;
  bool _loadFailed = false;
  int _retryCount = 0;
  Timer? _retryTimer;
  static const Duration _disposeDelay = Duration(milliseconds: 300);
  static const int _maxRetryCount = 4;
  static const Duration _cooldownRetryDelay = Duration(seconds: 30);

  static void _log(String message) {
    debugPrint('[AdmobKare] $message');
  }

  static bool get _supportsSharedPool => true;
  static bool get _usePlaceholderOnly => kDebugMode && !_renderLiveAdsInDebug;

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

  static Future<void> warmupPool(
      {int targetCount = _defaultWarmupCount}) async {
    if (_usePlaceholderOnly) return;
    if (!_supportsSharedPool) return;
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
          _log(
              'warmup loaded: ${loadedAd.responseInfo?.loadedAdapterResponseInfo?.adSourceName ?? 'unknown'} unit=$adUnitId platform=${Platform.operatingSystem}');
          if (_readyPool.length < _maxPoolSize) {
            _readyPool.add(loadedAd as BannerAd);
          } else {
            loadedAd.dispose();
          }
        },
        onAdFailedToLoad: (Ad failedAd, LoadAdError error) {
          _loadingCount = (_loadingCount - 1).clamp(0, 999);
          _log(
              'warmup failed: code=${error.code} domain=${error.domain} message=${error.message} unit=$adUnitId platform=${Platform.operatingSystem}');
          failedAd.dispose();
        },
      ),
    );

    ad.load();
  }

  BannerAd? _takePreloadedBanner() {
    if (!_supportsSharedPool) return null;
    if (_readyPool.isEmpty) return null;
    return _readyPool.removeAt(0);
  }

  bool _canRenderAd(BannerAd? ad) {
    if (!_isAdLoaded || ad == null) return false;
    return ad.responseInfo != null;
  }

  @override
  void initState() {
    super.initState();
    if (_usePlaceholderOnly) return;
    _attachBannerOrLoad();
  }

  void _attachBannerOrLoad() {
    final pooled = _takePreloadedBanner();
    if (pooled != null) {
      if (pooled.responseInfo == null) {
        try {
          pooled.dispose();
        } catch (_) {}
        _loadBanner();
        return;
      }
      _bannerAd = pooled;
      _isAdLoaded = true;
      _loadFailed = false;
      if (_supportsSharedPool) {
        unawaited(warmupPool());
      }
      if (mounted && !_isDisposed) {
        setState(() {});
      }
      return;
    }
    _loadBanner();
  }

  void _loadBanner() {
    final String adUnitId = _resolveAdUnitId();
    _log(
        'requesting banner unit=$adUnitId platform=${Platform.operatingSystem} debug=$kDebugMode');

    _retryTimer?.cancel();
    final previousAd = _bannerAd;
    _bannerAd = null;
    if (previousAd != null) {
      unawaited(Future<void>.delayed(_disposeDelay, () {
        try {
          previousAd.dispose();
        } catch (_) {}
      }));
    }
    if (mounted && !_isDisposed) {
      setState(() {
        _isAdLoaded = false;
        _loadFailed = false;
      });
    }

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          _retryCount = 0;
          _log(
              'loaded banner source=${ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ?? 'unknown'} unit=$adUnitId platform=${Platform.operatingSystem}');
          if (mounted && !_isDisposed) {
            setState(() {
              _isAdLoaded = true;
              _loadFailed = false;
            });
          }
          if (_supportsSharedPool) {
            unawaited(warmupPool());
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          _log(
              'failed banner code=${error.code} domain=${error.domain} message=${error.message} unit=$adUnitId platform=${Platform.operatingSystem}');
          ad.dispose();
          _bannerAd = null;
          if (_isDisposed) return;
          if (_retryCount < _maxRetryCount) {
            _retryCount += 1;
            final retryDelay = Duration(milliseconds: 800 * _retryCount);
            _log(
                'retrying banner in ${retryDelay.inMilliseconds}ms attempt=$_retryCount unit=$adUnitId platform=${Platform.operatingSystem}');
            if (mounted) {
              setState(() {
                _loadFailed = false;
                _isAdLoaded = false;
              });
            }
            _retryTimer = Timer(retryDelay, () {
              if (_isDisposed) return;
              _loadBanner();
            });
            return;
          }
          if (mounted && !_isDisposed) {
            setState(() {
              _loadFailed = true;
              _isAdLoaded = false;
            });
          }
          _retryTimer?.cancel();
          _retryTimer = Timer(_cooldownRetryDelay, () {
            if (_isDisposed) return;
            _retryCount = 0;
            _loadBanner();
          });
        },
        onAdOpened: (Ad ad) {
          _log(
              'opened banner unit=$adUnitId platform=${Platform.operatingSystem}');
        },
        onAdClosed: (Ad ad) {
          _log(
              'closed banner unit=$adUnitId platform=${Platform.operatingSystem}');
        },
        onAdImpression: (Ad ad) {
          _log(
              'impression banner unit=$adUnitId platform=${Platform.operatingSystem}');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _retryTimer?.cancel();
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
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    if (_usePlaceholderOnly) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          height: 250,
          child: Center(
            child: Text(
              'Debug reklam gizlendi',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        ),
      );
    }

    final ad = _bannerAd;
    if (_loadFailed || !_canRenderAd(ad)) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          height: 250,
          alignment: Alignment.center,
          child: _loadFailed
              ? const Text(
                  'Reklam yukleniyor',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                )
              : const CupertinoActivityIndicator(),
        ),
      );
    }
    final bannerAd = ad!;

    try {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                SizedBox(
                  width: bannerAd.size.width.toDouble(),
                  height: bannerAd.size.height.toDouble(),
                  child: AdWidget(
                    ad: bannerAd,
                    key: ValueKey('admob_${bannerAd.hashCode}'),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      );
    } catch (error, stackTrace) {
      _log('build failed: $error platform=${Platform.operatingSystem}');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'AdmobKare',
          context: ErrorDescription('while building AdmobKare'),
        ),
      );
      if (mounted && !_isDisposed) {
        scheduleMicrotask(() {
          if (!mounted || _isDisposed) return;
          setState(() {
            _loadFailed = true;
            _isAdLoaded = false;
          });
        });
      }
      return const SizedBox.shrink();
    }
  }
}
