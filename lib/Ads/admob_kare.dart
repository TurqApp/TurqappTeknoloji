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
import 'package:turqappv2/Modules/Education/education_controller.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';
import 'package:turqappv2/Runtime/primary_tab_router.dart';
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
    this.adSlotId,
    this.disposeImmediatelyWhenHidden = false,
    this.preferManagedSuggestionSurface = false,
  });

  final bool showChrome;
  final VoidCallback? onImpression;
  final EdgeInsetsGeometry contentPadding;
  final double liveAdOffsetX;
  final double promoFallbackOffsetX;
  final double promoFallbackExtraWidth;
  final bool forceSingleLinePromoChips;
  final String? suggestionPlacementId;
  final String? adSlotId;
  final bool disposeImmediatelyWhenHidden;
  final bool preferManagedSuggestionSurface;

  static Future<void> warmupPool({
    int targetCount = _AdmobKareState._poolTargetCount,
    int maxRequestCount = 1,
    bool bypassMinInterval = false,
    String debugSource = '',
  }) {
    return _AdmobKareState.warmupPool(
      targetCount: targetCount,
      maxRequestCount: maxRequestCount,
      bypassMinInterval: bypassMinInterval,
      debugSource: debugSource,
    );
  }

  static bool get hasReadyBanner => _AdmobKareState.hasReadyBanner;
  static bool get hasRenderableBanner => _AdmobKareState.hasRenderableBanner;
  static ValueListenable<int> get availabilityRevision =>
      _AdmobKareState._sharedAdAvailabilityRevision;
  static Map<String, Object> get debugState => _AdmobKareState.debugState;
  static void setScrollCriticalLiveAdBindingPaused(bool paused) {
    _AdmobKareState.setScrollCriticalLiveAdBindingPaused(paused);
  }

  @override
  State<AdmobKare> createState() => _AdmobKareState();
}

enum _StableAdSlotPhase {
  empty,
  loading,
  ready,
  bound,
  impressed,
}

class _StableAdSlotState {
  _StableAdSlotState(this.id);

  final String id;
  BannerAd? ad;
  _StableAdSlotPhase phase = _StableAdSlotPhase.empty;
  int ownerHash = 0;
  bool impressionReported = false;
  DateTime updatedAt = DateTime.now();

  bool get hasRenderableAd => ad?.responseInfo != null;
  bool get isOwned => ownerHash != 0;

  void mark(_StableAdSlotPhase nextPhase) {
    phase = nextPhase;
    updatedAt = DateTime.now();
  }
}

class _AdmobKareState extends State<AdmobKare> {
  static final List<BannerAd> _readyPool = <BannerAd>[];
  static final Map<String, _StableAdSlotState> _stableSlots =
      <String, _StableAdSlotState>{};
  static final ValueNotifier<int> _sharedAdAvailabilityRevision =
      ValueNotifier<int>(0);
  static final ValueNotifier<bool> _scrollCriticalLiveAdBindingPaused =
      ValueNotifier<bool>(false);
  static Timer? _scrollCriticalLiveAdBindingResumeTimer;
  static final Map<String, DateTime> _unitCooldownUntilById =
      <String, DateTime>{};
  static final Map<String, int> _managedSuggestionNextIndexByPlacement =
      <String, int>{};
  static final Random _suggestionRandom = Random();
  static int _loadingCount = 0;
  static DateTime? _globalCooldownUntil;
  static DateTime? _lastWarmupAttemptAt;
  static Timer? _deferredPoolTopUpTimer;
  static int _globalFailureBurstCount = 0;
  static Future<void>? _sdkInitFuture;
  static bool _sdkInitialized = false;
  static const int _poolTargetCount = 4;
  static const int _poolLowWaterMark = 2;
  static const int _poolTopUpBatchCount = 2;
  static const int _defaultWarmupCount = _poolTargetCount;
  static const int _maxPoolSize = 5;
  static const int _maxStableSlotCount = 12;
  static const Duration _warmupAttemptMinInterval = Duration(seconds: 8);
  static const int _failureBurstBeforeCooldown = 5;
  static const bool _renderLiveAdsInDebug = bool.fromEnvironment(
    'DEBUG_RENDER_ADMOB',
    defaultValue: true,
  );

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isDisposed = false;
  bool _loadFailed = false;
  bool _impressionReported = false;
  int _retryCount = 0;
  Timer? _retryTimer;
  Timer? _fallbackGateTimer;
  Timer? _stableHiddenDetachTimer;
  Timer? _visibilityLoadDebounceTimer;
  Timer? _scrollCriticalAttachDelayTimer;
  DateTime? _qaRequestStartedAt;
  late final Key _visibilityKey;
  bool _isVisible = false;
  bool _waitingForFuturePool = false;
  bool _liveAdEverRendered = false;
  static const Duration _disposeDelay = Duration(milliseconds: 300);
  static const int _maxRetryCount = 4;
  static const Duration _cooldownRetryDelay = Duration(seconds: 30);
  static const Duration _fallbackRevealDelay = Duration(milliseconds: 1200);
  static const Duration _feedVisibilityLoadDelay = Duration(milliseconds: 650);
  static const Duration _feedScrollCriticalAttachDelay =
      Duration(milliseconds: 30);
  static const Duration _scrollCriticalLiveAdBindingResumeDelay = Duration.zero;
  static const Duration _stableHiddenDetachDelay = Duration(seconds: 2);
  static const double _promoSlotHeight = 270;
  static const double _livePromoSlotHeight = 274;
  static const double _feedVisibilityLoadThreshold = 0.72;
  final SliderCacheService _sliderCacheService = SliderCacheService();
  final AdsAnalyticsService _adsAnalyticsService = const AdsAnalyticsService();
  TurqAppSuggestionConfig? _suggestionConfig;
  TurqAppSuggestionConfig? _fallbackSuggestionConfig;
  List<SliderResolvedItem> _suggestionSliderItems =
      const <SliderResolvedItem>[];
  int _visibleSuggestionIndex = 0;
  String _lastReportedManagedItemId = '';
  bool _allowFallbackSurface = false;

  static void _log(String message) {
    debugPrint('[AdmobKare] $message');
  }

  static void _notifySharedAdAvailabilityChanged() {
    _sharedAdAvailabilityRevision.value =
        _sharedAdAvailabilityRevision.value + 1;
  }

  static void setScrollCriticalLiveAdBindingPaused(bool paused) {
    if (!paused) {
      final activeTimer = _scrollCriticalLiveAdBindingResumeTimer;
      if (activeTimer != null && activeTimer.isActive) {
        return;
      }
      _scrollCriticalLiveAdBindingResumeTimer = Timer(
        _scrollCriticalLiveAdBindingResumeDelay,
        () {
          _scrollCriticalLiveAdBindingResumeTimer = null;
          if (!_scrollCriticalLiveAdBindingPaused.value) {
            return;
          }
          _scrollCriticalLiveAdBindingPaused.value = false;
          _log('scroll-critical live ad binding paused=false');
        },
      );
      return;
    }
    _scrollCriticalLiveAdBindingResumeTimer?.cancel();
    _scrollCriticalLiveAdBindingResumeTimer = null;
    if (_scrollCriticalLiveAdBindingPaused.value == paused) {
      return;
    }
    _scrollCriticalLiveAdBindingPaused.value = paused;
    _log('scroll-critical live ad binding paused=$paused');
  }

  static void _trimReadyPoolToLimit() {
    while (_readyPool.length > _maxPoolSize) {
      final ad = _readyPool.removeLast();
      try {
        ad.dispose();
      } catch (_) {}
    }
  }

  static void _trimStableSlots({String preserveSlotId = ''}) {
    if (_stableSlots.length <= _maxStableSlotCount) {
      return;
    }
    final removable = _stableSlots.values
        .where((slot) => slot.id != preserveSlotId && !slot.isOwned)
        .toList(growable: false)
      ..sort((left, right) => left.updatedAt.compareTo(right.updatedAt));
    for (final slot in removable) {
      if (_stableSlots.length <= _maxStableSlotCount) {
        break;
      }
      final removed = _stableSlots.remove(slot.id);
      final ad = removed?.ad;
      if (ad != null) {
        try {
          ad.dispose();
        } catch (_) {}
      }
      _log('stable slot evicted id=${slot.id} phase=${slot.phase.name}');
    }
  }

  static Future<void> _ensureSdkInitialized() async {
    if (_sdkInitialized) {
      return;
    }
    final pending = _sdkInitFuture;
    if (pending != null) {
      await pending;
      return;
    }
    final future = () async {
      await MobileAds.instance.initialize();
      _sdkInitialized = true;
      _log('sdk initialized platform=${Platform.operatingSystem}');
    }();
    _sdkInitFuture = future;
    try {
      await future;
    } catch (error) {
      _sdkInitialized = false;
      _log('sdk init failed: $error');
      rethrow;
    } finally {
      if (identical(_sdkInitFuture, future)) {
        _sdkInitFuture = null;
      }
    }
  }

  static bool get _supportsSharedPool => true;
  static bool get _usePlaceholderOnly => kDebugMode && !_renderLiveAdsInDebug;
  static bool get hasReadyBanner => _readyPool.isNotEmpty;
  static bool get hasRenderableBanner =>
      _readyPool.any((ad) => ad.responseInfo != null);
  static Map<String, Object> get debugState => <String, Object>{
        'sdkInitialized': _sdkInitialized,
        'readyPoolCount': _readyPool.length,
        'renderablePoolCount':
            _readyPool.where((ad) => ad.responseInfo != null).length,
        'loadingCount': _loadingCount,
        'cooldownActive': _globalCooldownRemaining() > Duration.zero,
      };
  bool get _usesManagedSuggestion =>
      (widget.suggestionPlacementId?.trim().isNotEmpty ?? false);
  String get _managedSuggestionPlacementId =>
      widget.suggestionPlacementId?.trim() ?? '';
  bool get _usesFeedFamilyAdBehavior {
    switch (_managedSuggestionPlacementId) {
      case 'feed':
      case 'profile':
        return true;
    }
    return false;
  }

  bool get _requiresStableFeedVisibilityForLoad => _usesFeedFamilyAdBehavior;
  bool get _usesScrollCriticalPoolOnly => _usesFeedFamilyAdBehavior;
  bool get _prefersManagedSuggestionSurface =>
      widget.preferManagedSuggestionSurface && _usesManagedSuggestion;
  String get _stableAdSlotKey => widget.adSlotId?.trim() ?? '';
  bool get _usesStableAdSlot => _stableAdSlotKey.isNotEmpty;
  _StableAdSlotState? get _stableSlotState =>
      _usesStableAdSlot ? _stableSlots[_stableAdSlotKey] : null;

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
    const bool isTestMode = false;
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
    String debugSource = '',
  }) async {
    if (_usePlaceholderOnly) return;
    if (!_supportsSharedPool) return;
    if (targetCount <= 0) return;
    if (maxRequestCount <= 0) return;
    if (_globalCooldownRemaining() > Duration.zero) return;
    _trimReadyPoolToLimit();
    final effectiveTargetCount = min(targetCount, _poolTargetCount);
    final currentMissing =
        effectiveTargetCount - (_readyPool.length + _loadingCount);
    if (currentMissing <= 0) return;
    final now = DateTime.now();
    final lastAttempt = _lastWarmupAttemptAt;
    if (!bypassMinInterval &&
        lastAttempt != null &&
        now.difference(lastAttempt) < _warmupAttemptMinInterval) {
      return;
    }
    _lastWarmupAttemptAt = now;
    final sourceLabel =
        debugSource.trim().isEmpty ? '' : ' source=${debugSource.trim()}';
    _log(
      'warmup request$sourceLabel target=$effectiveTargetCount '
      'requestedTarget=$targetCount maxRequestCount=$maxRequestCount '
      'bypass=$bypassMinInterval state=$debugState',
    );
    try {
      await _ensureSdkInitialized();
    } catch (_) {
      return;
    }

    final missing = effectiveTargetCount - (_readyPool.length + _loadingCount);
    _log(
      'warmup evaluate$sourceLabel target=$effectiveTargetCount '
      'missing=$missing state=$debugState',
    );
    if (missing <= 0) return;

    final requestCount = missing.clamp(0, maxRequestCount);
    for (int i = 0; i < requestCount; i++) {
      _loadingCount++;
      _createAndLoadBannerForPool();
    }
  }

  static void _schedulePoolTopUp({
    Duration delay = Duration.zero,
    int targetCount = _poolTargetCount,
    int maxRequestCount = _poolTopUpBatchCount,
  }) {
    if (delay <= Duration.zero) {
      unawaited(warmupPool(
        targetCount: targetCount,
        maxRequestCount: maxRequestCount,
        bypassMinInterval: false,
        debugSource: 'pool_top_up',
      ));
      return;
    }
    final activeTimer = _deferredPoolTopUpTimer;
    if (activeTimer != null && activeTimer.isActive) {
      return;
    }
    _deferredPoolTopUpTimer = Timer(delay, () {
      _deferredPoolTopUpTimer = null;
      unawaited(warmupPool(
        targetCount: targetCount,
        maxRequestCount: maxRequestCount,
        bypassMinInterval: false,
        debugSource: 'deferred_pool_top_up',
      ));
    });
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
            _trimReadyPoolToLimit();
            _notifySharedAdAvailabilityChanged();
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

  bool _isRenderableBanner(BannerAd? ad) => ad?.responseInfo != null;

  _StableAdSlotState _ensureStableSlotState() {
    final slotId = _stableAdSlotKey;
    final slot = _stableSlots.putIfAbsent(
      slotId,
      () => _StableAdSlotState(slotId),
    );
    _trimStableSlots(preserveSlotId: slotId);
    return slot;
  }

  bool _tryAttachStableSlotAd() {
    if (!_usesStableAdSlot) {
      return false;
    }
    final slot = _stableSlotState;
    if (slot == null || !slot.hasRenderableAd) {
      return false;
    }
    final owner = identityHashCode(this);
    if (slot.ownerHash != 0 && slot.ownerHash != owner) {
      _log(
        'stable slot busy id=${slot.id} owner=${slot.ownerHash} '
        'requester=$owner phase=${slot.phase.name}',
      );
      return true;
    }
    if (identical(_bannerAd, slot.ad) && _isAdLoaded) {
      _loadFailed = false;
      _allowFallbackSurface = false;
      _waitingForFuturePool = false;
      _impressionReported = slot.impressionReported;
      slot.ownerHash = owner;
      slot.mark(_StableAdSlotPhase.bound);
      return true;
    }
    _bannerAd = slot.ad;
    _isAdLoaded = true;
    _loadFailed = false;
    _allowFallbackSurface = false;
    _waitingForFuturePool = false;
    _impressionReported = slot.impressionReported;
    slot.ownerHash = owner;
    slot.mark(_StableAdSlotPhase.bound);
    _log('stable slot attach id=${slot.id} phase=${slot.phase.name}');
    if (mounted && !_isDisposed) {
      setState(() {});
    }
    return true;
  }

  void _bindAdToStableSlot(BannerAd ad) {
    if (!_usesStableAdSlot) {
      return;
    }
    final slot = _ensureStableSlotState();
    slot.ad = ad;
    slot.ownerHash = identityHashCode(this);
    slot.impressionReported = false;
    slot.mark(_StableAdSlotPhase.bound);
    _log('stable slot bound id=${slot.id}');
  }

  void _detachStableSlotOwner({
    required bool resetLocalState,
    required String reason,
  }) {
    if (!_usesStableAdSlot) {
      return;
    }
    final slot = _stableSlotState;
    if (slot == null) {
      return;
    }
    final owner = identityHashCode(this);
    if (slot.ownerHash == owner) {
      slot.ownerHash = 0;
      slot.mark(slot.hasRenderableAd
          ? _StableAdSlotPhase.ready
          : _StableAdSlotPhase.empty);
      _log('stable slot detached id=${slot.id} reason=$reason');
    }
    if (resetLocalState) {
      _bannerAd = null;
      _isAdLoaded = false;
      _loadFailed = false;
      _allowFallbackSurface = false;
      _waitingForFuturePool = false;
      _liveAdEverRendered = false;
    }
  }

  void _detachStableSlotOwnerById(
    String slotId, {
    required bool resetLocalState,
    required String reason,
  }) {
    final normalized = slotId.trim();
    if (normalized.isEmpty) {
      return;
    }
    final slot = _stableSlots[normalized];
    if (slot == null) {
      return;
    }
    final owner = identityHashCode(this);
    if (slot.ownerHash == owner) {
      slot.ownerHash = 0;
      slot.mark(slot.hasRenderableAd
          ? _StableAdSlotPhase.ready
          : _StableAdSlotPhase.empty);
      _log('stable slot detached id=${slot.id} reason=$reason');
    }
    if (resetLocalState) {
      _bannerAd = null;
      _isAdLoaded = false;
      _loadFailed = false;
      _allowFallbackSurface = false;
      _waitingForFuturePool = false;
      _liveAdEverRendered = false;
    }
  }

  void _scheduleStableHiddenDetach() {
    _stableHiddenDetachTimer?.cancel();
    _stableHiddenDetachTimer = Timer(_stableHiddenDetachDelay, () {
      _stableHiddenDetachTimer = null;
      if (_isDisposed || _isVisible) {
        return;
      }
      _detachStableSlotOwner(
        resetLocalState: true,
        reason: 'hidden_page_deferred',
      );
      _notifySharedAdAvailabilityChanged();
      if (mounted && !_isDisposed) {
        setState(() {});
      }
    });
    _log(
      'stable slot hidden detach deferred id=$_stableAdSlotKey '
      'delayMs=${_stableHiddenDetachDelay.inMilliseconds}',
    );
  }

  @override
  void initState() {
    super.initState();
    _visibilityKey = ValueKey<String>('admob-kare-${identityHashCode(this)}');
    _sharedAdAvailabilityRevision.addListener(_handleSharedAdAvailability);
    _scrollCriticalLiveAdBindingPaused.addListener(
      _handleScrollCriticalAdBindingChanged,
    );
    if (_usePlaceholderOnly) return;
    if (_usesScrollCriticalPoolOnly && !_prefersManagedSuggestionSurface) {
      unawaited(warmupPool(
        targetCount: _poolTargetCount,
        maxRequestCount: _poolTopUpBatchCount,
        bypassMinInterval: false,
        debugSource: 'feed_slot_init',
      ));
    }
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
    final previousSlot = oldWidget.adSlotId?.trim() ?? '';
    final nextSlot = widget.adSlotId?.trim() ?? '';
    if (previousPlacement == nextPlacement && previousSlot == nextSlot) {
      return;
    }
    if (previousSlot != nextSlot) {
      _stableHiddenDetachTimer?.cancel();
      _stableHiddenDetachTimer = null;
      _detachStableSlotOwnerById(
        previousSlot,
        resetLocalState: true,
        reason: 'slot_changed',
      );
    }
    _fallbackGateTimer?.cancel();
    _allowFallbackSurface = false;
    _suggestionConfig = null;
    _waitingForFuturePool = false;
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

  void _handleSharedAdAvailability() {
    if (_isDisposed || _usePlaceholderOnly || !_isVisible) {
      return;
    }
    if (_prefersManagedSuggestionSurface) {
      return;
    }
    if (_usesScrollCriticalPoolOnly && _waitingForFuturePool) {
      if (!_scrollCriticalLiveAdBindingPaused.value) {
        _waitingForFuturePool = false;
        _log(
          'pool ready attach scheduled after settle placement=$_managedSuggestionPlacementId '
          'slot=$_stableAdSlotKey state=$debugState',
        );
        _scheduleScrollCriticalAttachAfterSettle();
        return;
      }
      _log(
        'pool ready deferred for next scroll-critical slot '
        'placement=$_managedSuggestionPlacementId slot=$_stableAdSlotKey '
        'state=$debugState',
      );
      return;
    }
    if (_canRenderAd(_bannerAd)) {
      if (mounted) {
        setState(() {});
      }
      return;
    }
    if (_bannerAd != null && !_isAdLoaded) {
      return;
    }
    if (hasReadyBanner || hasRenderableBanner) {
      _attachBannerOrLoad();
    }
  }

  void _handleScrollCriticalAdBindingChanged() {
    if (_isDisposed || !_usesScrollCriticalPoolOnly) {
      return;
    }
    if (_prefersManagedSuggestionSurface) {
      return;
    }
    if (_scrollCriticalLiveAdBindingPaused.value) {
      _scrollCriticalAttachDelayTimer?.cancel();
      _scrollCriticalAttachDelayTimer = null;
      return;
    }
    if (!_scrollCriticalLiveAdBindingPaused.value &&
        _isVisible &&
        (_waitingForFuturePool ||
            _isRenderableBanner(_stableSlotState?.ad) ||
            _bannerAd == null ||
            !_isAdLoaded)) {
      _waitingForFuturePool = false;
      _scheduleScrollCriticalAttachAfterSettle();
      return;
    }
  }

  void _scheduleScrollCriticalAttachAfterSettle() {
    if (_prefersManagedSuggestionSurface) {
      return;
    }
    if (!_usesScrollCriticalPoolOnly) {
      _attachBannerOrLoad();
      return;
    }
    _scrollCriticalAttachDelayTimer?.cancel();
    _scrollCriticalAttachDelayTimer = Timer(
      _feedScrollCriticalAttachDelay,
      () {
        _scrollCriticalAttachDelayTimer = null;
        if (_isDisposed || !_isVisible) return;
        if (_scrollCriticalLiveAdBindingPaused.value) return;
        _attachBannerOrLoad();
      },
    );
  }

  void _attachBannerOrLoad() {
    if (!_canStartOrRetryLoad()) {
      return;
    }
    if (_prefersManagedSuggestionSurface) {
      return;
    }
    if (_usesScrollCriticalPoolOnly &&
        _scrollCriticalLiveAdBindingPaused.value) {
      _waitingForFuturePool = true;
      return;
    }
    if (_tryAttachStableSlotAd()) {
      return;
    }
    final pooled = _takePreloadedBanner();
    if (pooled != null) {
      if (pooled.responseInfo == null) {
        try {
          pooled.dispose();
        } catch (_) {}
        if (_usesScrollCriticalPoolOnly) {
          _waitingForFuturePool = true;
          _schedulePoolTopUp(delay: const Duration(seconds: 4));
          return;
        }
        _loadBanner();
        return;
      }
      _bannerAd = pooled;
      _isAdLoaded = true;
      _loadFailed = false;
      _allowFallbackSurface = false;
      _impressionReported = false;
      _liveAdEverRendered = false;
      _bindAdToStableSlot(pooled);
      _fallbackGateTimer?.cancel();
      _notifySharedAdAvailabilityChanged();
      if (_supportsSharedPool) {
        if (_readyPool.length <= _poolLowWaterMark) {
          _schedulePoolTopUp(
            delay: _usesScrollCriticalPoolOnly
                ? const Duration(seconds: 4)
                : Duration.zero,
          );
        }
      }
      if (mounted && !_isDisposed) {
        setState(() {});
      }
      _waitingForFuturePool = false;
      return;
    }
    if (_usesScrollCriticalPoolOnly) {
      _waitingForFuturePool = true;
      if (_usesStableAdSlot) {
        _ensureStableSlotState().mark(_StableAdSlotPhase.loading);
      }
      _log(
        'pool miss; skip inline live load placement=$_managedSuggestionPlacementId '
        'slot=$_stableAdSlotKey state=$debugState',
      );
      _armFallbackGate();
      _schedulePoolTopUp(delay: const Duration(seconds: 4));
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
    _loadBanner();
  }

  void _scheduleAttachBannerOrLoad() {
    _visibilityLoadDebounceTimer?.cancel();
    if (_requiresStableFeedVisibilityForLoad) {
      _visibilityLoadDebounceTimer = Timer(_feedVisibilityLoadDelay, () {
        if (_isDisposed) return;
        _scheduleScrollCriticalAttachAfterSettle();
      });
      return;
    }
    _attachBannerOrLoad();
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

  void _armFallbackGate() {
    _fallbackGateTimer?.cancel();
    if (_isDisposed || !_isVisible || _canRenderAd(_bannerAd)) {
      return;
    }
    _fallbackGateTimer = Timer(_fallbackRevealDelay, () {
      if (_isDisposed || !mounted || !_isVisible || _canRenderAd(_bannerAd)) {
        return;
      }
      setState(() {
        _allowFallbackSurface = true;
      });
    });
  }

  void _disposeBannerAd(
    BannerAd ad, {
    required String reason,
    Duration delay = _disposeDelay,
  }) {
    _log(
      'disposing banner reason=$reason visible=$_isVisible '
      'loaded=$_isAdLoaded pool=${_readyPool.length}',
    );
    Future<void> disposeAd() async {
      try {
        ad.dispose();
      } catch (_) {}
    }

    if (delay <= Duration.zero) {
      unawaited(disposeAd());
      return;
    }
    unawaited(Future<void>.delayed(delay, disposeAd));
  }

  void _releaseBannerForHiddenPage() {
    final ad = _bannerAd;
    if (ad == null) return;
    if (_usesStableAdSlot) {
      _scheduleStableHiddenDetach();
      return;
    }
    _bannerAd = null;
    _isAdLoaded = false;
    _loadFailed = false;
    _allowFallbackSurface = false;
    _impressionReported = false;
    _waitingForFuturePool = false;
    _liveAdEverRendered = false;
    _disposeBannerAd(
      ad,
      reason: 'hidden_page',
      delay:
          widget.disposeImmediatelyWhenHidden ? Duration.zero : _disposeDelay,
    );
    _notifySharedAdAvailabilityChanged();
    if (mounted && !_isDisposed) {
      setState(() {});
    }
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    final threshold = _requiresStableFeedVisibilityForLoad
        ? _feedVisibilityLoadThreshold
        : 0.01;
    final nextVisible = info.visibleFraction > threshold;
    if (_isVisible == nextVisible) {
      return;
    }
    _isVisible = nextVisible;
    if (!_isVisible) {
      _retryTimer?.cancel();
      _fallbackGateTimer?.cancel();
      _visibilityLoadDebounceTimer?.cancel();
      _waitingForFuturePool = false;
      _releaseBannerForHiddenPage();
      return;
    }
    _stableHiddenDetachTimer?.cancel();
    _stableHiddenDetachTimer = null;
    if (_prefersManagedSuggestionSurface) {
      if (_usesManagedSuggestion) {
        if (_suggestionSliderItems.isNotEmpty) {
          _advanceManagedSuggestionIndex();
        }
        _queueManagedSuggestionImpressionIfVisible();
      }
      if (mounted && !_isDisposed) {
        setState(() {});
      }
      return;
    }
    if (_usesManagedSuggestion && _suggestionSliderItems.isNotEmpty) {
      _advanceManagedSuggestionIndex();
      if (_canRenderAd(_bannerAd)) {
        return;
      }
      if (_allowFallbackSurface || _loadFailed) {
        _queueManagedSuggestionImpressionIfVisible();
      } else {
        _armFallbackGate();
      }
    }
    if (_bannerAd == null || !_isAdLoaded) {
      _scheduleAttachBannerOrLoad();
    }
  }

  void _loadBanner() {
    if (!_sdkInitialized) {
      unawaited(() async {
        try {
          await _ensureSdkInitialized();
        } catch (_) {
          return;
        }
        if (_isDisposed) {
          return;
        }
        _scheduleAttachBannerOrLoad();
      }());
      return;
    }
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
    _liveAdEverRendered = false;
    if (previousAd != null) {
      _disposeBannerAd(previousAd, reason: 'replace_before_load');
    }
    if (mounted && !_isDisposed) {
      setState(() {
        _isAdLoaded = false;
        _loadFailed = false;
        _allowFallbackSurface = false;
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
              _allowFallbackSurface = false;
            });
          }
          if (ad is BannerAd) {
            _bindAdToStableSlot(ad);
          }
          _fallbackGateTimer?.cancel();
          _notifySharedAdAvailabilityChanged();
          if (_supportsSharedPool) {
            unawaited(warmupPool(
              bypassMinInterval: false,
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
            if (mounted && !_isDisposed) {
              setState(() {
                _allowFallbackSurface = true;
              });
            }
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
          _armFallbackGate();
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
            final slot = _stableSlotState;
            if (slot != null && slot.ownerHash == identityHashCode(this)) {
              slot.impressionReported = true;
              slot.mark(_StableAdSlotPhase.impressed);
              _log('stable slot impressed id=${slot.id}');
            }
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
    _sharedAdAvailabilityRevision.removeListener(_handleSharedAdAvailability);
    _scrollCriticalLiveAdBindingPaused.removeListener(
      _handleScrollCriticalAdBindingChanged,
    );
    _retryTimer?.cancel();
    _fallbackGateTimer?.cancel();
    _stableHiddenDetachTimer?.cancel();
    _visibilityLoadDebounceTimer?.cancel();
    _scrollCriticalAttachDelayTimer?.cancel();
    final ad = _bannerAd;
    _isAdLoaded = false;
    _bannerAd = null;
    _liveAdEverRendered = false;
    if (_usesStableAdSlot) {
      _detachStableSlotOwner(
        resetLocalState: false,
        reason: 'widget_dispose',
      );
    } else if (ad != null) {
      _disposeBannerAd(
        ad,
        reason: 'widget_dispose',
        delay:
            widget.disposeImmediatelyWhenHidden ? Duration.zero : _disposeDelay,
      );
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
      final liveAdBindingPaused = _usesScrollCriticalPoolOnly &&
          _scrollCriticalLiveAdBindingPaused.value;
      final hasRenderableAd = _canRenderAd(ad);
      final shouldPreserveVisibleLiveAd =
          hasRenderableAd && (_liveAdEverRendered || _isVisible);
      final canRenderLiveAd = hasRenderableAd &&
          (shouldPreserveVisibleLiveAd ||
              (!_loadFailed && !liveAdBindingPaused));
      final preferManagedSuggestionSurface = _prefersManagedSuggestionSurface;
      final showManagedSuggestion = _usesManagedSuggestion &&
          (_suggestionSliderItems.isNotEmpty || preferManagedSuggestionSurface);
      if (canRenderLiveAd && !preferManagedSuggestionSurface) {
        _liveAdEverRendered = true;
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
                height: _livePromoSlotHeight,
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
        if (preferManagedSuggestionSurface ||
            _allowFallbackSurface ||
            _loadFailed ||
            liveAdBindingPaused) {
          _queueManagedSuggestionImpressionIfVisible();
          child = _buildManagedSuggestionSlot();
        } else {
          child = _buildPendingAdSlot();
        }
      } else {
        if (!widget.showChrome) {
          child = const SizedBox.shrink();
        } else if (liveAdBindingPaused) {
          child = _buildDeferredAdSlot();
        } else if (!_allowFallbackSurface && !_loadFailed) {
          child = _buildPendingAdSlot();
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

  Widget _buildDeferredAdSlot() {
    final fallbackSurface = SizedBox(
      height: _promoSlotHeight,
      child: _buildPromoFrame(
        child: _buildPromoFallbackSurface(),
      ),
    );
    return Padding(
      padding: widget.contentPadding,
      child: widget.promoFallbackOffsetX == 0
          ? fallbackSurface
          : Transform.translate(
              offset: Offset(widget.promoFallbackOffsetX, 0),
              child: fallbackSurface,
            ),
    );
  }

  Widget _buildPendingAdSlot() {
    if (!widget.showChrome) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: widget.contentPadding,
      child: SizedBox(
        height: _promoSlotHeight,
        child: _buildPromoFrame(
          child: const Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
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
        .where((placement) =>
            _pasajTabIdForSuggestionPlacement(placement.id).isNotEmpty)
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

  String _pasajTabIdForSuggestionPlacement(String placementId) {
    switch (placementId) {
      case 'market':
        return PasajTabIds.market;
      case 'job':
        return PasajTabIds.jobFinder;
      case 'scholarship':
        return PasajTabIds.scholarships;
      case 'answer_key':
        return PasajTabIds.answerKey;
      case 'practice_exam':
        return PasajTabIds.onlineExam;
      case 'tutoring':
        return PasajTabIds.tutoring;
    }
    return '';
  }

  String _pasajTabIdFromSuggestionText(String value) {
    final text = value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('%c3%b6', 'o')
        .replaceAll('%c4%b1', 'i')
        .replaceAll('%c5%9f', 's');
    if (text.contains('online_sinav') ||
        text.contains('online-sinav') ||
        text.contains('online sinav') ||
        text.contains('online_exam') ||
        text.contains('online-exam')) {
      return PasajTabIds.onlineExam;
    }
    if (text.contains('deneme') ||
        text.contains('cikmis') ||
        text.contains('practice_exams') ||
        text.contains('previous_questions')) {
      return PasajTabIds.practiceExams;
    }
    if (text.contains('cevap') ||
        text.contains('answer_key') ||
        text.contains('answer-key') ||
        text.contains('optical')) {
      return PasajTabIds.answerKey;
    }
    if (text.contains('burs') || text.contains('scholarship')) {
      return PasajTabIds.scholarships;
    }
    if (text.contains('is_bul') ||
        text.contains('is-bul') ||
        text.contains('isveren') ||
        text.contains('job')) {
      return PasajTabIds.jobFinder;
    }
    if (text.contains('ozel_ders') ||
        text.contains('ozel-ders') ||
        text.contains('tutoring')) {
      return PasajTabIds.tutoring;
    }
    if (text.contains('market') || text.contains('pazar')) {
      return PasajTabIds.market;
    }
    return '';
  }

  String _normalizePasajTabId(String value) {
    final normalized = value.trim();
    if (pasajTabs.contains(normalized)) {
      return normalized;
    }
    final legacy = pasajLegacyTitleToId(normalized);
    if (pasajTabs.contains(legacy)) {
      return legacy;
    }
    return _pasajTabIdFromSuggestionText(normalized);
  }

  String _pasajTabIdForManagedSuggestionItem(SliderResolvedItem? item) {
    if (item == null) {
      return '';
    }
    final explicitTab = _normalizePasajTabId(item.targetTabId);
    if (explicitTab.isNotEmpty) {
      return explicitTab;
    }
    final placementTab =
        _pasajTabIdForSuggestionPlacement(item.targetPlacementId);
    if (placementTab.isNotEmpty) {
      return placementTab;
    }
    return _pasajTabIdFromSuggestionText('${item.itemId} ${item.source}');
  }

  void _openSuggestionPasajTab({
    required String placementId,
    required String tabId,
  }) {
    final targetTabId = _normalizePasajTabId(tabId);
    if (targetTabId.isEmpty) return;

    final placementTabId = _pasajTabIdForSuggestionPlacement(placementId);
    final resolvedPlacementId =
        placementTabId == targetTabId ? placementId : 'item_target';

    final openedEducation = const PrimaryTabRouter().openEducation();
    final education = ensureEducationController(permanent: true);

    void openTarget([int attemptsLeft = 8]) {
      final openedTab = education.openPasajTabId(targetTabId);
      _log(
        'suggestion tap placement=$resolvedPlacementId sourcePlacement=$placementId tab=$targetTabId '
        'openedEducation=$openedEducation openedTab=$openedTab '
        'attemptsLeft=$attemptsLeft',
      );
      if (openedTab || attemptsLeft <= 0) return;
      Future<void>.delayed(const Duration(milliseconds: 80), () {
        openTarget(attemptsLeft - 1);
      });
    }

    openTarget();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openTarget();
      Future<void>.delayed(const Duration(milliseconds: 120), openTarget);
    });
  }

  Widget _wrapSuggestionPasajTap({
    required String placementId,
    required String tabId,
    required Widget child,
  }) {
    final targetTabId = _normalizePasajTabId(tabId);
    if (targetTabId.isEmpty) return child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openSuggestionPasajTab(
        placementId: placementId,
        tabId: targetTabId,
      ),
      child: child,
    );
  }

  String _tapTabIdForSuggestionSlot({required bool hasSlider}) {
    if (hasSlider) {
      final itemTabId =
          _pasajTabIdForManagedSuggestionItem(_currentManagedSuggestionItem);
      if (itemTabId.isNotEmpty) {
        return itemTabId;
      }
    }
    final primaryPlacementId = hasSlider
        ? _currentSuggestionConfig.placementId
        : _currentFallbackSuggestionConfig.placementId;
    final primaryTabId = _pasajTabIdForSuggestionPlacement(primaryPlacementId);
    if (primaryTabId.isNotEmpty) {
      return primaryTabId;
    }
    return _pasajTabIdForSuggestionPlacement(
      _currentFallbackSuggestionConfig.placementId,
    );
  }

  Widget _buildManagedSuggestionSlot() {
    final hasSlider = _suggestionSliderItems.isNotEmpty;
    final tapTabId = _tapTabIdForSuggestionSlot(
      hasSlider: hasSlider,
    );
    final tapPlacementId = hasSlider
        ? _currentSuggestionConfig.placementId
        : _currentFallbackSuggestionConfig.placementId;
    final slotBody = SizedBox(
      height: _promoSlotHeight,
      child: _buildPromoFrame(
        child: hasSlider
            ? _buildManagedSliderSurface()
            : _buildPromoFallbackSurface(),
      ),
    );
    final tappableSlotBody = _wrapSuggestionPasajTap(
      placementId: tapPlacementId,
      tabId: tapTabId,
      child: slotBody,
    );

    if (!widget.showChrome) {
      return tappableSlotBody;
    }

    return Padding(
      padding: widget.contentPadding,
      child: widget.promoFallbackOffsetX == 0
          ? tappableSlotBody
          : Transform.translate(
              offset: Offset(widget.promoFallbackOffsetX, 0),
              child: tappableSlotBody,
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
