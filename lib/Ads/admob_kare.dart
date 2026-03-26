import 'dart:async';
import 'dart:io';
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
  bool _impressionReported = false;
  int _retryCount = 0;
  Timer? _retryTimer;
  Timer? _fallbackPromoTimer;
  DateTime? _qaRequestStartedAt;
  late final Key _visibilityKey;
  bool _isVisible = false;
  bool _showPromoFallback = false;
  static const Duration _disposeDelay = Duration(milliseconds: 300);
  static const Duration _fallbackPromoDelay = Duration(milliseconds: 650);
  static const int _maxRetryCount = 4;
  static const Duration _cooldownRetryDelay = Duration(seconds: 30);

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

  void _schedulePromoFallback() {
    if (_showPromoFallback || _isDisposed || !_isVisible) return;
    _fallbackPromoTimer?.cancel();
    _fallbackPromoTimer = Timer(_fallbackPromoDelay, () {
      if (!mounted || _isDisposed || !_isVisible) return;
      if (_canRenderAd(_bannerAd)) return;
      setState(() {
        _showPromoFallback = true;
      });
    });
  }

  void _resetPromoFallback() {
    _fallbackPromoTimer?.cancel();
    if (!_showPromoFallback) return;
    if (mounted && !_isDisposed) {
      setState(() {
        _showPromoFallback = false;
      });
    } else {
      _showPromoFallback = false;
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
      _resetPromoFallback();
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
      _fallbackPromoTimer?.cancel();
      return;
    }
    if (_bannerAd == null || !_isAdLoaded) {
      _schedulePromoFallback();
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
    _schedulePromoFallback();

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
              _showPromoFallback = false;
            });
          }
          _fallbackPromoTimer?.cancel();
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
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _retryTimer?.cancel();
    _fallbackPromoTimer?.cancel();
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
    } else {
      final ad = _bannerAd;
      if (_loadFailed || !_canRenderAd(ad)) {
        if (!widget.showChrome) {
          child = const SizedBox.shrink();
        } else if (_showPromoFallback) {
          child = Padding(
            padding: widget.contentPadding,
            child: _buildPromoFallbackSurface(),
          );
        } else {
          child = Padding(
            padding: widget.contentPadding,
            child: Container(
              height: 250,
              alignment: Alignment.center,
              child: const CupertinoActivityIndicator(),
            ),
          );
        }
      } else {
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
            child = Center(
              child: Padding(
                padding: widget.contentPadding,
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
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
                      renderedAdBody,
                      const SizedBox(height: 4),
                    ],
                  ),
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
      }
    }
    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _handleVisibilityChanged,
      child: child,
    );
  }

  Widget _buildPromoFallbackCard() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF0F172A),
            Color(0xFF0F766E),
          ],
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
                color: CupertinoColors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'TurqApp önerisi',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pasaj, ilanlar ve denemeleri keşfet',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'TurqApp içindeki fırsatları öne çıkarıyoruz.',
              style: TextStyle(
                color: Color(0xFFD9F7F1),
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const Spacer(),
            widget.forceSingleLinePromoChips
                ? const Row(
                    children: [
                      Expanded(
                        child: _PromoChip(
                          label: 'MobilPazar',
                          expandedLayout: true,
                        ),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: _PromoChip(
                          label: 'İş İlanları',
                          expandedLayout: true,
                        ),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: _PromoChip(
                          label: 'Denemeler',
                          expandedLayout: true,
                        ),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: _PromoChip(
                          label: 'Burslar',
                          expandedLayout: true,
                        ),
                      ),
                    ],
                  )
                : const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PromoChip(label: 'MobilPazar'),
                      _PromoChip(label: 'İş İlanları'),
                      _PromoChip(label: 'Denemeler'),
                      _PromoChip(label: 'Burslar'),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoFallbackSurface() {
    if (widget.promoFallbackOffsetX == 0 &&
        widget.promoFallbackExtraWidth == 0) {
      return _buildPromoFallbackCard();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final expandedWidth =
            constraints.maxWidth + widget.promoFallbackExtraWidth;
        final targetWidth =
            expandedWidth > 0 ? expandedWidth : constraints.maxWidth;

        return Transform.translate(
          offset: Offset(widget.promoFallbackOffsetX, 0),
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: targetWidth,
            maxWidth: targetWidth,
            child: SizedBox(
              width: targetWidth,
              child: _buildPromoFallbackCard(),
            ),
          ),
        );
      },
    );
  }
}

class _PromoChip extends StatelessWidget {
  const _PromoChip({
    required this.label,
    this.expandedLayout = false,
  });

  final String label;
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
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
