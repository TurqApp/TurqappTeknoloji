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
  int _retryCount = 0;
  Timer? _retryTimer;
  static const Duration _disposeDelay = Duration(milliseconds: 300);
  static const int _maxRetryCount = 2;

  static void _log(String message) {
    debugPrint('[AdmobKare] $message');
  }

  static bool get _supportsSharedPool => Platform.isAndroid;

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
          if (_readyPool.length < 8) {
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
    if (_isDisposed || _loadFailed) {
      return const SizedBox.shrink();
    }

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
