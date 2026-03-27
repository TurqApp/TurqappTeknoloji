import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:turqappv2/Core/Services/Ads/ads_analytics_service.dart';
import 'package:turqappv2/Core/Services/Ads/admob_unit_config_service.dart';
import 'package:turqappv2/Core/Services/Ads/turqapp_suggestion_config_service.dart';
import 'package:turqappv2/Core/Services/qa_lab_bridge.dart';
import 'package:turqappv2/Core/Services/slider_cache_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
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
    this.suggestionPlacementId,
  });

  final bool showChrome;
  final VoidCallback? onImpression;
  final EdgeInsetsGeometry contentPadding;
  final double liveAdOffsetX;
  final double promoFallbackOffsetX;
  final double promoFallbackExtraWidth;
  final bool forceSingleLinePromoChips;
  final String? suggestionPlacementId;

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
  static final List<BannerAd> _readyPool = <BannerAd>[];
  static final Map<String, DateTime> _unitCooldownUntilById =
      <String, DateTime>{};
  static final Map<String, int> _managedSuggestionNextIndexByPlacement =
      <String, int>{};
  static final Random _suggestionRandom = Random();
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
  final SliderCacheService _sliderCacheService = SliderCacheService();
  final AdsAnalyticsService _adsAnalyticsService = const AdsAnalyticsService();
  TurqAppSuggestionConfig? _suggestionConfig;
  TurqAppSuggestionConfig? _fallbackSuggestionConfig;
  List<SliderResolvedItem> _suggestionSliderItems =
      const <SliderResolvedItem>[];
  int _visibleSuggestionIndex = 0;
  String _lastReportedManagedItemId = '';

  static void _log(String message) {
    debugPrint('[AdmobKare] $message');
  }

  static bool get _supportsSharedPool => true;
  static bool get _usePlaceholderOnly => kDebugMode && !_renderLiveAdsInDebug;
  static bool get hasReadyBanner => _readyPool.isNotEmpty;
  static bool get hasRenderableBanner =>
      _readyPool.any((ad) => ad.responseInfo != null);
  bool get _usesManagedSuggestion =>
      (widget.suggestionPlacementId?.trim().isNotEmpty ?? false);
  String get _managedSuggestionPlacementId =>
      widget.suggestionPlacementId?.trim() ?? '';

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
    final service = ensureAdmobUnitConfigService();
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
    return fallbackCandidate ??
        service.nextSquareAdUnitId(isTestMode: isTestMode);
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
    if (_usesManagedSuggestion) {
      _fallbackSuggestionConfig =
          _pickRandomFallbackConfig(const <String, TurqAppSuggestionConfig>{});
      unawaited(_bootstrapManagedSuggestion());
    }
  }

  @override
  void didUpdateWidget(covariant AdmobKare oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousPlacement = oldWidget.suggestionPlacementId?.trim() ?? '';
    final nextPlacement = widget.suggestionPlacementId?.trim() ?? '';
    if (previousPlacement == nextPlacement) {
      return;
    }
    _suggestionConfig = null;
    _fallbackSuggestionConfig = nextPlacement.isEmpty
        ? null
        : _pickRandomFallbackConfig(const <String, TurqAppSuggestionConfig>{});
    _suggestionSliderItems = const <SliderResolvedItem>[];
    _visibleSuggestionIndex = 0;
    _lastReportedManagedItemId = '';
    if (nextPlacement.isNotEmpty) {
      unawaited(_bootstrapManagedSuggestion(forceRefresh: true));
    }
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
    if (_usePlaceholderOnly || _isDisposed) {
      return false;
    }
    final route = ModalRoute.of(context);
    final isRouteCurrent = route?.isCurrent ?? true;
    return _isVisible && isRouteCurrent;
  }

  Future<void> _bootstrapManagedSuggestion({
    bool forceRefresh = false,
  }) async {
    final placementId = widget.suggestionPlacementId?.trim() ?? '';
    if (placementId.isEmpty || _isDisposed) {
      return;
    }

    final placement = TurqAppSuggestionPlacements.byId(placementId);
    if (placement == null) {
      return;
    }

    final configs = await TurqAppSuggestionConfigService.instance.loadAll(
      forceRefresh: forceRefresh,
    );
    final config =
        configs[placementId] ?? TurqAppSuggestionConfig.defaultsFor(placement);
    final fallbackConfig = _pickRandomFallbackConfig(configs);
    if (!mounted || _isDisposed) return;
    setState(() {
      _suggestionConfig = config;
      _fallbackSuggestionConfig = fallbackConfig;
    });

    final snapshot = await _sliderCacheService.readSnapshot(config.sliderId);
    if (!mounted || _isDisposed) return;
    if (snapshot.hasItems) {
      setState(() {
        _suggestionSliderItems = snapshot.resolvedItems;
      });
      _ensureVisibleSuggestionIndexInRange();
      unawaited(_sliderCacheService.warmImages(snapshot.items));
    }

    unawaited(_refreshManagedSuggestionSlider(config.sliderId));
  }

  Future<void> _refreshManagedSuggestionSlider(String sliderId) async {
    try {
      final remote = await _sliderCacheService.refreshAndCacheItems(sliderId);
      if (!mounted || _isDisposed) return;
      setState(() {
        _suggestionSliderItems = remote;
      });
      _ensureVisibleSuggestionIndexInRange();
      if (_suggestionSliderItems.isEmpty && _isVisible) {
        _attachBannerOrLoad();
      } else {
        _queueManagedSuggestionImpressionIfVisible();
      }
    } catch (_) {}
  }

  void _ensureVisibleSuggestionIndexInRange() {
    final items = _suggestionSliderItems;
    if (items.isEmpty) {
      _visibleSuggestionIndex = 0;
      _lastReportedManagedItemId = '';
      return;
    }
    if (_visibleSuggestionIndex >= items.length) {
      _visibleSuggestionIndex = 0;
    }
  }

  void _advanceManagedSuggestionIndex() {
    final placementId = _managedSuggestionPlacementId;
    final items = _suggestionSliderItems;
    if (placementId.isEmpty || items.isEmpty) {
      return;
    }
    final nextIndex =
        (_managedSuggestionNextIndexByPlacement[placementId] ?? 0) %
            items.length;
    _managedSuggestionNextIndexByPlacement[placementId] =
        (nextIndex + 1) % items.length;
    if (_visibleSuggestionIndex == nextIndex) {
      _queueManagedSuggestionImpressionIfVisible();
      return;
    }
    if (!mounted || _isDisposed) {
      _visibleSuggestionIndex = nextIndex;
      _queueManagedSuggestionImpressionIfVisible();
      return;
    }
    setState(() {
      _visibleSuggestionIndex = nextIndex;
    });
    _queueManagedSuggestionImpressionIfVisible();
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
    if (_usesManagedSuggestion && _suggestionSliderItems.isNotEmpty) {
      _advanceManagedSuggestionIndex();
      if (_canRenderAd(_bannerAd)) {
        return;
      }
      _queueManagedSuggestionImpressionIfVisible();
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
          _lastReportedManagedItemId = '';
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
      final showManagedSuggestion =
          _usesManagedSuggestion && _suggestionSliderItems.isNotEmpty;
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
              });
            });
          }
          child = const SizedBox.shrink();
        }
      } else if (showManagedSuggestion) {
        _queueManagedSuggestionImpressionIfVisible();
        child = _buildManagedSuggestionSlot();
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

  Widget _buildPromoFallbackCard() {
    final config = _currentFallbackSuggestionConfig;
    final accentColor = _promoAccentColorFor(config.placementId);
    final accentTint = accentColor.withValues(alpha: 0.12);
    return Container(
      height: _promoSlotHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFF8F9FB),
            Color(0xFFF3F6F4),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentTint,
              ),
              child: const SizedBox(
                width: 118,
                height: 118,
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: accentTint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  config.title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0x14000000),
                    ),
                  ),
                  child: const Text(
                    'TurqApp Önerisi',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  config.headline,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.14,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  config.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 13,
                    height: 1.38,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0x14000000),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _promoCtaLabelFor(config.placementId),
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        CupertinoIcons.arrow_right,
                        size: 16,
                        color: accentColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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

  TurqAppSuggestionConfig get _currentSuggestionConfig {
    final placementId = widget.suggestionPlacementId?.trim() ?? '';
    final placement = TurqAppSuggestionPlacements.byId(placementId);
    if (placement == null) {
      return TurqAppSuggestionConfig(
        placementId: placementId,
        title: placementId,
        sliderId: 'ads_$placementId',
        headline: TurqAppSuggestionConfig.defaultHeadline,
        body: TurqAppSuggestionConfig.defaultBody,
      );
    }
    return _suggestionConfig ?? TurqAppSuggestionConfig.defaultsFor(placement);
  }

  TurqAppSuggestionConfig get _currentFallbackSuggestionConfig =>
      _fallbackSuggestionConfig ?? _currentSuggestionConfig;

  TurqAppSuggestionConfig _pickRandomFallbackConfig(
    Map<String, TurqAppSuggestionConfig> configs,
  ) {
    final available = TurqAppSuggestionPlacements.entries
        .map(
          (placement) =>
              configs[placement.id] ??
              TurqAppSuggestionConfig.defaultsFor(placement),
        )
        .toList(growable: false);
    if (available.isEmpty) {
      return _currentSuggestionConfig;
    }
    return available[_suggestionRandom.nextInt(available.length)];
  }

  Color _promoAccentColorFor(String placementId) {
    switch (placementId) {
      case 'feed':
        return const Color(0xFF0F766E);
      case 'profile':
        return const Color(0xFF2563EB);
      case 'market':
        return const Color(0xFFB45309);
      case 'scholarship':
        return const Color(0xFF7C3AED);
      case 'answer_key':
        return const Color(0xFF0F766E);
      case 'job':
        return const Color(0xFFBE123C);
      case 'practice_exam':
        return const Color(0xFF1D4ED8);
      case 'tutoring':
        return const Color(0xFF15803D);
    }
    return const Color(0xFF0F766E);
  }

  String _promoCtaLabelFor(String placementId) {
    switch (placementId) {
      case 'market':
      case 'job':
      case 'tutoring':
        return 'İncelemeye başla';
      case 'scholarship':
        return 'Fırsatları gör';
      case 'answer_key':
        return 'Kaynakları keşfet';
      case 'practice_exam':
        return 'Denemeleri gör';
      case 'profile':
        return 'Seçili içerikleri aç';
      case 'feed':
        return 'Bugünün öne çıkanları';
    }
    return 'Şimdi keşfet';
  }

  Widget _buildManagedSuggestionSlot() {
    final hasSlider = _suggestionSliderItems.isNotEmpty;
    final slotBody = SizedBox(
      height: _promoSlotHeight,
      child: _buildPromoFrame(
        child: hasSlider
            ? _buildManagedSliderSurface()
            : _buildPromoFallbackSurface(),
      ),
    );

    if (!widget.showChrome) {
      return slotBody;
    }

    return Padding(
      padding: widget.contentPadding,
      child: widget.promoFallbackOffsetX == 0
          ? slotBody
          : Transform.translate(
              offset: Offset(widget.promoFallbackOffsetX, 0),
              child: slotBody,
            ),
    );
  }

  Widget _buildManagedSliderCard() {
    if (_suggestionSliderItems.isEmpty) {
      return _buildPromoFallbackCard();
    }
    final item = _currentManagedSuggestionItem;
    final source = item?.source ?? '';
    if (source.isEmpty) {
      return _buildPromoFallbackCard();
    }
    return ColoredBox(
      color: CupertinoColors.systemGrey6,
      child: SizedBox(
        height: _promoSlotHeight,
        width: double.infinity,
        child: _buildManagedSliderItem(source),
      ),
    );
  }

  Widget _buildManagedSliderItem(String source) {
    if (source.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: source,
        cacheManager: TurqImageCacheManager.instance,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, _) => _buildPromoFallbackCard(),
        errorWidget: (context, _, __) => _buildPromoFallbackCard(),
      );
    }
    return Image.asset(
      source,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, _, __) => _buildPromoFallbackCard(),
    );
  }

  Widget _buildManagedSliderSurface() {
    if (widget.promoFallbackExtraWidth == 0) {
      return _buildManagedSliderCard();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final expandedWidth =
            constraints.maxWidth + widget.promoFallbackExtraWidth;
        final targetWidth =
            expandedWidth > 0 ? expandedWidth : constraints.maxWidth;
        final sliderCard = SizedBox(
          width: targetWidth,
          child: _buildManagedSliderCard(),
        );

        return SizedBox(
          width: constraints.maxWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: Offset(widget.promoFallbackOffsetX, 0),
                child: sliderCard,
              ),
            ],
          ),
        );
      },
    );
  }

  SliderResolvedItem? get _currentManagedSuggestionItem {
    if (_suggestionSliderItems.isEmpty) {
      return null;
    }
    return _suggestionSliderItems[
        _visibleSuggestionIndex.clamp(0, _suggestionSliderItems.length - 1)];
  }

  void _queueManagedSuggestionImpressionIfVisible() {
    if (!_usesManagedSuggestion || !_isVisible || _canRenderAd(_bannerAd)) {
      return;
    }
    scheduleMicrotask(() async {
      if (!mounted || _isDisposed || !_isVisible || _canRenderAd(_bannerAd)) {
        return;
      }
      final item = _currentManagedSuggestionItem;
      if (item == null || !item.isRemote || item.itemId.trim().isEmpty) {
        return;
      }
      if (_lastReportedManagedItemId == item.itemId) {
        return;
      }
      _lastReportedManagedItemId = item.itemId;
      await _adsAnalyticsService.logManagedSliderView(
        sliderId: _currentSuggestionConfig.sliderId,
        itemId: item.itemId,
        surfaceId: _managedSuggestionPlacementId,
        sourceType: 'suggestion_slot',
      );
    });
  }
}
