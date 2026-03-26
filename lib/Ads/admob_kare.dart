import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:turqappv2/Core/Services/Ads/admob_unit_config_service.dart';
import 'package:turqappv2/Core/Services/qa_lab_bridge.dart';
import 'package:visibility_detector/visibility_detector.dart';

class AdmobKare extends StatefulWidget {
  const AdmobKare({
    super.key,
    this.showChrome = true,
    this.onImpression,
    this.contentPadding = const EdgeInsets.all(8),
    this.liveAdOffsetX = 0,
    this.promoFallbackOffsetX = 0,
    this.promoFallbackExtraWidth = 0,
    this.forceSingleLinePromoChips = false,
  });

  final bool showChrome;
  final VoidCallback? onImpression;
  final EdgeInsetsGeometry contentPadding;
  final double liveAdOffsetX;
  final double promoFallbackOffsetX;
  final double promoFallbackExtraWidth;
  final bool forceSingleLinePromoChips;

  static Future<void> warmupPool({
    int targetCount = 5,
    int maxRequestCount = 1,
    bool bypassMinInterval = false,
  }) {
    return _AdmobKareState.warmupPool(
      targetCount: targetCount,
      maxRequestCount: maxRequestCount,
      bypassMinInterval: bypassMinInterval,
    );
  }

  static bool get hasReadyBanner => _AdmobKareState.hasReadyBanner;
  static bool get hasRenderableBanner => _AdmobKareState.hasRenderableBanner;

  @override
  State<AdmobKare> createState() => _AdmobKareState();
}

class _AdmobKareState extends State<AdmobKare> {
  static const List<_PromoFallbackPalette> _promoFallbackPalettes =
      <_PromoFallbackPalette>[
    _PromoFallbackPalette(
      colors: <Color>[
        Color(0xFFD8F3DC),
        Color(0xFFB7E4C7),
        Color(0xFF95D5B2),
      ],
      badgeBackgroundColor: Color(0x66FFFFFF),
      badgeBorderColor: Color(0x6695D5B2),
      titleColor: Color(0xFF1B4332),
      subtitleColor: Color(0xFF2D6A4F),
    ),
    _PromoFallbackPalette(
      colors: <Color>[
        Color(0xFFFFE5D9),
        Color(0xFFFFCAD4),
        Color(0xFFF4ACB7),
      ],
      badgeBackgroundColor: Color(0x66FFFFFF),
      badgeBorderColor: Color(0x66F4ACB7),
      titleColor: Color(0xFF6D2745),
      subtitleColor: Color(0xFF8F3F5C),
    ),
    _PromoFallbackPalette(
      colors: <Color>[
        Color(0xFFE3F2FD),
        Color(0xFFBBDEFB),
        Color(0xFF90CAF9),
      ],
      badgeBackgroundColor: Color(0x66FFFFFF),
      badgeBorderColor: Color(0x6690CAF9),
      titleColor: Color(0xFF0D3B66),
      subtitleColor: Color(0xFF355070),
    ),
    _PromoFallbackPalette(
      colors: <Color>[
        Color(0xFFFFF1C1),
        Color(0xFFFFE59A),
        Color(0xFFFFD166),
      ],
      badgeBackgroundColor: Color(0x66FFFFFF),
      badgeBorderColor: Color(0x66FFD166),
      titleColor: Color(0xFF6B4F00),
      subtitleColor: Color(0xFF7A5C00),
    ),
    _PromoFallbackPalette(
      colors: <Color>[
        Color(0xFFEDE7F6),
        Color(0xFFD1C4E9),
        Color(0xFFB39DDB),
      ],
      badgeBackgroundColor: Color(0x66FFFFFF),
      badgeBorderColor: Color(0x66B39DDB),
      titleColor: Color(0xFF3F2B63),
      subtitleColor: Color(0xFF5E548E),
    ),
    _PromoFallbackPalette(
      colors: <Color>[
        Color(0xFFDFF7F2),
        Color(0xFFB8F2E6),
        Color(0xFF9BE7D8),
      ],
      badgeBackgroundColor: Color(0x66FFFFFF),
      badgeBorderColor: Color(0x669BE7D8),
      titleColor: Color(0xFF0B525B),
      subtitleColor: Color(0xFF1B6B75),
    ),
    _PromoFallbackPalette(
      colors: <Color>[
        Color(0xFFFDE2E4),
        Color(0xFFF9BEC7),
        Color(0xFFF694C1),
      ],
      badgeBackgroundColor: Color(0x66FFFFFF),
      badgeBorderColor: Color(0x66F694C1),
      titleColor: Color(0xFF6A2040),
      subtitleColor: Color(0xFF8A345A),
    ),
  ];
  static final List<BannerAd> _readyPool = <BannerAd>[];
  static final Map<String, DateTime> _unitCooldownUntilById =
      <String, DateTime>{};
  static int _loadingCount = 0;
  static DateTime? _globalCooldownUntil;
  static DateTime? _lastWarmupAttemptAt;
  static int _globalFailureBurstCount = 0;
  static const int _defaultWarmupCount = 5;
  static const int _maxPoolSize = 8;
  static const Duration _warmupAttemptMinInterval = Duration(seconds: 8);
  static const int _failureBurstBeforeCooldown = 5;
  static const bool _renderLiveAdsInDebug = bool.fromEnvironment(
    'DEBUG_RENDER_ADMOB',
    defaultValue: false,
  );

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isDisposed = false;
  bool _loadFailed = false;
  bool _isLoadingAd = false;
  bool _impressionReported = false;
  int _retryCount = 0;
  Timer? _retryTimer;
  DateTime? _qaRequestStartedAt;
  late final Key _visibilityKey;
  bool _isVisible = false;
  static const Duration _disposeDelay = Duration(milliseconds: 300);
  static const int _maxRetryCount = 4;
  static const Duration _cooldownRetryDelay = Duration(seconds: 30);
  static const double _promoSlotHeight = 270;
  late final _PromoFallbackPalette _promoFallbackPalette =
      _promoFallbackPalettes[Random().nextInt(_promoFallbackPalettes.length)];

  static void _log(String message) {
    debugPrint('[AdmobKare] $message');
  }

  static bool get _supportsSharedPool => true;
  static bool get _usePlaceholderOnly => kDebugMode && !_renderLiveAdsInDebug;
  static bool get hasReadyBanner => _readyPool.isNotEmpty;
  static bool get hasRenderableBanner =>
      _readyPool.any((ad) => ad.responseInfo != null);

  static Duration _globalCooldownRemaining() {
    final until = _globalCooldownUntil;
    if (until == null) {
      return Duration.zero;
    }
    final remaining = until.difference(DateTime.now());
    if (remaining > Duration.zero) {
      return remaining;
    }
    _globalCooldownUntil = null;
    return Duration.zero;
  }

  static String _resolveAdUnitId() {
    final bool isTestMode = kDebugMode;
    final service = AdmobUnitConfigService.ensure();
    final availableIds = service.squareAdUnitIdsForCurrentPlatform(
      isTestMode: isTestMode,
    );
    if (availableIds.isEmpty) {
      return service.nextSquareAdUnitId(isTestMode: isTestMode);
    }

    String? fallbackCandidate;
    for (int i = 0; i < availableIds.length; i++) {
      final candidate = service.nextSquareAdUnitId(isTestMode: isTestMode);
      fallbackCandidate ??= candidate;
      if (_unitCooldownRemaining(candidate) == Duration.zero) {
        return candidate;
      }
    }
    return fallbackCandidate ?? service.nextSquareAdUnitId(isTestMode: isTestMode);
  }

  static Duration _unitCooldownRemaining(String adUnitId) {
    final until = _unitCooldownUntilById[adUnitId];
    if (until == null) {
      return Duration.zero;
    }
    final remaining = until.difference(DateTime.now());
    if (remaining > Duration.zero) {
      return remaining;
    }
    _unitCooldownUntilById.remove(adUnitId);
    return Duration.zero;
  }

  static void _markUnitCooldown(
    String adUnitId,
    LoadAdError error,
  ) {
    if (error.code == 3) {
      _unitCooldownUntilById[adUnitId] =
          DateTime.now().add(const Duration(seconds: 20));
      return;
    }
    final isRetryThrottled = error.code == 1 &&
        error.message.contains('Too many recently failed requests');
    if (isRetryThrottled) {
      _unitCooldownUntilById[adUnitId] =
          DateTime.now().add(_cooldownRetryDelay);
    }
  }

  static Future<void> warmupPool({
    int targetCount = _defaultWarmupCount,
    int maxRequestCount = 1,
    bool bypassMinInterval = false,
  }) async {
    if (_usePlaceholderOnly) return;
    if (!_supportsSharedPool) return;
    if (targetCount <= 0) return;
    if (maxRequestCount <= 0) return;
    if (_globalCooldownRemaining() > Duration.zero) return;

    final now = DateTime.now();
    final lastAttempt = _lastWarmupAttemptAt;
    if (!bypassMinInterval &&
        lastAttempt != null &&
        now.difference(lastAttempt) < _warmupAttemptMinInterval) {
      return;
    }
    _lastWarmupAttemptAt = now;

    final missing = targetCount - (_readyPool.length + _loadingCount);
    if (missing <= 0) return;

    final requestCount = missing.clamp(0, maxRequestCount);
    for (int i = 0; i < requestCount; i++) {
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
          _globalFailureBurstCount = 0;
          _globalCooldownUntil = null;
          _unitCooldownUntilById.remove(adUnitId);
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
          final isRetryThrottled = error.code == 1 &&
              error.message.contains('Too many recently failed requests');
          _globalFailureBurstCount =
              (_globalFailureBurstCount + 1).clamp(1, 99);
          _markUnitCooldown(adUnitId, error);
          if (isRetryThrottled ||
              _globalFailureBurstCount >= _failureBurstBeforeCooldown) {
            _globalCooldownUntil = DateTime.now().add(_cooldownRetryDelay);
            _log(
                'warmup cooldown in ${_cooldownRetryDelay.inMilliseconds}ms after code=${error.code} unit=$adUnitId platform=${Platform.operatingSystem}');
          }
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
    final renderableIndex =
        _readyPool.indexWhere((ad) => ad.responseInfo != null);
    if (renderableIndex >= 0) {
      return _readyPool.removeAt(renderableIndex);
    }
    return _readyPool.removeAt(0);
  }

  bool _canRenderAd(BannerAd? ad) {
    if (!_isAdLoaded || ad == null) return false;
    return ad.responseInfo != null;
  }

  @override
  void initState() {
    super.initState();
    _visibilityKey = ValueKey<String>('admob-kare-${identityHashCode(this)}');
    if (_usePlaceholderOnly) return;
  }

  void _attachBannerOrLoad() {
    if (!_canStartOrRetryLoad()) {
      return;
    }
    final cooldownRemaining = _globalCooldownRemaining();
    if (cooldownRemaining > Duration.zero) {
      _scheduleRetry(
        delay: cooldownRemaining,
        resetRetryCount: true,
      );
      return;
    }
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
      _isLoadingAd = false;
      _loadFailed = false;
      _impressionReported = false;
      if (_supportsSharedPool) {
        unawaited(warmupPool(
          bypassMinInterval: true,
        ));
      }
      if (mounted && !_isDisposed) {
        setState(() {});
      }
      return;
    }
    _loadBanner();
  }

  bool _canStartOrRetryLoad() {
    if (_usePlaceholderOnly || _isDisposed) return false;
    final route = ModalRoute.of(context);
    final isRouteCurrent = route?.isCurrent ?? true;
    return _isVisible && isRouteCurrent;
  }

  void _scheduleRetry({
    required Duration delay,
    bool resetRetryCount = false,
  }) {
    _retryTimer?.cancel();
    if (mounted && !_isDisposed) {
      setState(() {
        _loadFailed = true;
        _isAdLoaded = false;
        _isLoadingAd = false;
      });
    }
    _retryTimer = Timer(delay, () {
      if (_isDisposed) return;
      if (resetRetryCount) {
        _retryCount = 0;
      }
      _attachBannerOrLoad();
    });
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    final nextVisible = info.visibleFraction > 0.01;
    if (_isVisible == nextVisible) {
      return;
    }
    _isVisible = nextVisible;
    if (!_isVisible) {
      _retryTimer?.cancel();
      return;
    }
    if (_bannerAd == null || !_isAdLoaded) {
      _attachBannerOrLoad();
    }
  }

  void _loadBanner() {
    if (!_canStartOrRetryLoad()) {
      return;
    }
    final String adUnitId = _resolveAdUnitId();
    _log(
        'requesting banner unit=$adUnitId platform=${Platform.operatingSystem} debug=$kDebugMode');
    _qaRequestStartedAt = DateTime.now();
    recordQALabAdEvent(
      stage: 'requested',
      placement: 'medium_rectangle',
      metadata: <String, dynamic>{
        'adUnitId': adUnitId,
        'retryCount': _retryCount,
        'platform': Platform.operatingSystem,
      },
    );

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
        _isLoadingAd = true;
        _loadFailed = false;
      });
    }
    _impressionReported = false;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          _retryCount = 0;
          _globalFailureBurstCount = 0;
          _globalCooldownUntil = null;
          _unitCooldownUntilById.remove(adUnitId);
          final latencyMs = _qaRequestStartedAt == null
              ? 0
              : DateTime.now().difference(_qaRequestStartedAt!).inMilliseconds;
          _log(
              'loaded banner source=${ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ?? 'unknown'} unit=$adUnitId platform=${Platform.operatingSystem}');
          recordQALabAdEvent(
            stage: 'loaded',
            placement: 'medium_rectangle',
            metadata: <String, dynamic>{
              'adUnitId': adUnitId,
              'latencyMs': latencyMs,
              'source':
                  ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
                      'unknown',
              'platform': Platform.operatingSystem,
            },
          );
          if (mounted && !_isDisposed) {
            setState(() {
              _isAdLoaded = true;
              _isLoadingAd = false;
              _loadFailed = false;
            });
          }
          if (_supportsSharedPool) {
            unawaited(warmupPool(
              bypassMinInterval: true,
            ));
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          final latencyMs = _qaRequestStartedAt == null
              ? 0
              : DateTime.now().difference(_qaRequestStartedAt!).inMilliseconds;
          final isRetryThrottled = error.code == 1 &&
              error.message.contains('Too many recently failed requests');
          _globalFailureBurstCount =
              (_globalFailureBurstCount + 1).clamp(1, 99);
          _markUnitCooldown(adUnitId, error);
          _log(
              'failed banner code=${error.code} domain=${error.domain} message=${error.message} unit=$adUnitId platform=${Platform.operatingSystem}');
          recordQALabAdEvent(
            stage: 'failed',
            placement: 'medium_rectangle',
            metadata: <String, dynamic>{
              'adUnitId': adUnitId,
              'latencyMs': latencyMs,
              'errorCode': error.code,
              'domain': error.domain,
              'message': error.message,
              'retryCount': _retryCount,
              'platform': Platform.operatingSystem,
            },
          );
          ad.dispose();
          _bannerAd = null;
          if (_isDisposed) return;
          _isLoadingAd = false;
          final shouldEnterCooldown = isRetryThrottled ||
              _globalFailureBurstCount >= _failureBurstBeforeCooldown ||
              _retryCount >= _maxRetryCount;
          if (shouldEnterCooldown) {
            _globalCooldownUntil = DateTime.now().add(_cooldownRetryDelay);
            _log(
                'cooldown retry in ${_cooldownRetryDelay.inMilliseconds}ms after code=${error.code} unit=$adUnitId platform=${Platform.operatingSystem}');
            recordQALabAdEvent(
              stage: 'retry_cooldown',
              placement: 'medium_rectangle',
              metadata: <String, dynamic>{
                'adUnitId': adUnitId,
                'latencyMs': latencyMs,
                'errorCode': error.code,
                'failureBurstCount': _globalFailureBurstCount,
                'retryDelayMs': _cooldownRetryDelay.inMilliseconds,
                'platform': Platform.operatingSystem,
              },
            );
            _scheduleRetry(
              delay: _cooldownRetryDelay,
              resetRetryCount: true,
            );
            return;
          }
          _retryCount += 1;
          final retryDelay = Duration(milliseconds: 800 * _retryCount);
          _log(
              'retrying banner in ${retryDelay.inMilliseconds}ms attempt=$_retryCount unit=$adUnitId platform=${Platform.operatingSystem}');
          recordQALabAdEvent(
            stage: 'retry_scheduled',
            placement: 'medium_rectangle',
            metadata: <String, dynamic>{
              'adUnitId': adUnitId,
              'retryCount': _retryCount,
              'retryDelayMs': retryDelay.inMilliseconds,
              'platform': Platform.operatingSystem,
            },
          );
          if (mounted && !_isDisposed) {
            setState(() {
              _loadFailed = false;
              _isAdLoaded = false;
              _isLoadingAd = false;
            });
          }
          _scheduleRetry(delay: retryDelay);
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
          recordQALabAdEvent(
            stage: 'impression',
            placement: 'medium_rectangle',
            metadata: <String, dynamic>{
              'adUnitId': adUnitId,
              'platform': Platform.operatingSystem,
            },
          );
          if (!_impressionReported) {
            _impressionReported = true;
            widget.onImpression?.call();
          }
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
    _isLoadingAd = false;
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
    Widget child;
    if (_isDisposed) {
      child = const SizedBox.shrink();
    } else if (_usePlaceholderOnly) {
      child = const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          height: _promoSlotHeight,
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
    } else {
      final ad = _bannerAd;
      final canRenderLiveAd = !_loadFailed && _canRenderAd(ad);
      if (canRenderLiveAd) {
        final bannerAd = ad!;

        try {
          final adBody = SizedBox(
            width: bannerAd.size.width.toDouble(),
            height: bannerAd.size.height.toDouble(),
            child: AdWidget(
              ad: bannerAd,
              key: ValueKey('admob_${bannerAd.hashCode}'),
            ),
          );
          final renderedAdBody = widget.liveAdOffsetX == 0
              ? adBody
              : Transform.translate(
                  offset: Offset(widget.liveAdOffsetX, 0),
                  child: adBody,
                );
          if (!widget.showChrome) {
            child = Center(child: renderedAdBody);
          } else {
            child = Padding(
              padding: widget.contentPadding,
              child: SizedBox(
                height: _promoSlotHeight,
                child: _buildPromoFrame(
                  child: _buildLiveAdSurface(renderedAdBody),
                ),
              ),
            );
          }
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
                _isLoadingAd = false;
              });
            });
          }
          child = const SizedBox.shrink();
        }
      } else if (_isLoadingAd && !_loadFailed) {
        if (!widget.showChrome) {
          child = const SizedBox.shrink();
        } else {
          child = Padding(
            padding: widget.contentPadding,
            child: SizedBox(
              height: _promoSlotHeight,
              child: _buildPromoFrame(
                child: _buildAdLoadingSurface(),
              ),
            ),
          );
        }
      } else {
        if (!widget.showChrome) {
          child = const SizedBox.shrink();
        } else {
          final fallbackSurface = SizedBox(
            height: _promoSlotHeight,
            child: _buildPromoFrame(
              child: _buildPromoFallbackSurface(),
            ),
          );
          child = Padding(
            padding: widget.contentPadding,
            child: widget.promoFallbackOffsetX == 0
                ? fallbackSurface
                : Transform.translate(
                    offset: Offset(widget.promoFallbackOffsetX, 0),
                    child: fallbackSurface,
                  ),
          );
        }
      }
    }
    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _handleVisibilityChanged,
      child: child,
    );
  }

  Widget _buildPromoFrame({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x338E8E93),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }

  Widget _buildLiveAdSurface(Widget renderedAdBody) {
    return ColoredBox(
      color: CupertinoColors.systemGrey6,
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
          renderedAdBody,
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildAdLoadingSurface() {
    return const ColoredBox(
      color: CupertinoColors.systemGrey6,
      child: Center(
        child: CupertinoActivityIndicator(radius: 12),
      ),
    );
  }

  Widget _buildPromoFallbackCard() {
    final palette = _promoFallbackPalette;
    return Container(
      height: _promoSlotHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.colors,
          stops: <double>[0, 0.62, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: palette.badgeBackgroundColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: palette.badgeBorderColor,
                ),
              ),
              child: Text(
                'TurqApp önerisi',
                style: TextStyle(
                  color: palette.titleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Fırsat, gelişim ve ihtiyaç aynı yerde',
              style: TextStyle(
                color: palette.titleColor,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'TurqApp içindeki fırsatları öne çıkarıyoruz.',
              style: TextStyle(
                color: palette.subtitleColor,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const Spacer(),
            LayoutBuilder(
              builder: (context, constraints) {
                final useSingleLinePromoChips =
                    widget.forceSingleLinePromoChips ||
                        constraints.maxWidth >= 248;
                return useSingleLinePromoChips
                    ? _buildSingleLinePromoChips(palette)
                    : _buildWrappedPromoChips(palette);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoFallbackSurface() {
    if (widget.promoFallbackExtraWidth == 0) {
      return _buildPromoFallbackCard();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final expandedWidth =
            constraints.maxWidth + widget.promoFallbackExtraWidth;
        final targetWidth =
            expandedWidth > 0 ? expandedWidth : constraints.maxWidth;
        final fallbackCard = SizedBox(
          width: targetWidth,
          child: _buildPromoFallbackCard(),
        );

        return SizedBox(
          width: constraints.maxWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: Offset(widget.promoFallbackOffsetX, 0),
                child: fallbackCard,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSingleLinePromoChips(_PromoFallbackPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: SizedBox(
      height: 34,
        child: Row(
          children: [
            Expanded(
              child: _PromoChip(
                label: 'MobilPazar',
                expandedLayout: true,
                textColor: palette.titleColor,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _PromoChip(
                label: 'İş İlanları',
                expandedLayout: true,
                textColor: palette.titleColor,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _PromoChip(
                label: 'Denemeler',
                expandedLayout: true,
                textColor: palette.titleColor,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _PromoChip(
                label: 'Burslar',
                expandedLayout: true,
                textColor: palette.titleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrappedPromoChips(_PromoFallbackPalette palette) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _PromoChip(
          label: 'MobilPazar',
          textColor: palette.titleColor,
        ),
        _PromoChip(
          label: 'İş İlanları',
          textColor: palette.titleColor,
        ),
        _PromoChip(
          label: 'Denemeler',
          textColor: palette.titleColor,
        ),
        _PromoChip(
          label: 'Burslar',
          textColor: palette.titleColor,
        ),
      ],
    );
  }
}

class _PromoFallbackPalette {
  const _PromoFallbackPalette({
    required this.colors,
    required this.badgeBackgroundColor,
    required this.badgeBorderColor,
    required this.titleColor,
    required this.subtitleColor,
  });

  final List<Color> colors;
  final Color badgeBackgroundColor;
  final Color badgeBorderColor;
  final Color titleColor;
  final Color subtitleColor;
}

class _PromoChip extends StatelessWidget {
  const _PromoChip({
    required this.label,
    required this.textColor,
    this.expandedLayout = false,
  });

  final String label;
  final Color textColor;
  final bool expandedLayout;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: expandedLayout
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.18),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
