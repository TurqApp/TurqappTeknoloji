import 'dart:async';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Models/posts_model.dart';
import '../../../main.dart';
import '../../../hls_player/hls_video_adapter.dart';
import '../../../Core/Services/SegmentCache/prefetch_scheduler.dart';
import '../../../Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import '../../../Core/Services/qa_lab_bridge.dart';
import '../../../Core/Services/video_telemetry_service.dart';
import '../../../Core/Services/playback_handle.dart';
import '../../../Core/Services/playback_execution_service.dart';
import '../../../Core/Services/global_video_adapter_pool.dart';
import '../../../Ads/admob_kare.dart';
import '../../Agenda/agenda_controller.dart';
import '../../Explore/explore_controller.dart';
import '../../NavBar/nav_bar_controller.dart';
import '../../Profile/MyProfile/profile_controller.dart';
import '../../Profile/Archives/archives_controller.dart';
import '../../Profile/LikedPosts/liked_posts_controller.dart';
import '../../Profile/Settings/settings_controller.dart';
import '../../SocialProfile/social_profile_controller.dart';
import '../../Agenda/TopTags/top_tags_contoller.dart';
import '../../Agenda/TagPosts/tag_posts_controller.dart';
import '../../Agenda/FloodListing/flood_listing_controller.dart';
import '../../PlaybackRuntime/playback_cache_runtime_service.dart';
import 'post_content_controller.dart';

part 'post_content_base_lifecycle_part.dart';
part 'post_content_base_playback_part.dart';
part 'post_content_base_visibility_part.dart';

/// Base widget/state that encapsulates the shared behaviour between
/// Modern (AgendaContent) and Classic content cards.
abstract class PostContentBase extends StatefulWidget {
  const PostContentBase({
    super.key,
    required this.model,
    required this.isPreview,
    required this.shouldPlay,
    this.instanceTag,
    required this.isReshared,
    required this.reshareUserID,
    required this.showComments,
    required this.showArchivePost,
  });

  final PostsModel model;
  final bool isPreview;
  final bool shouldPlay;
  final String? instanceTag;
  final bool isReshared;
  final String? reshareUserID;
  final bool showComments;
  final bool showArchivePost;

  /// Factory for the specific controller implementation.
  PostContentController createController();
}

mixin PostContentBaseState<T extends PostContentBase> on State<T>
    implements RouteAware {
  late final AgendaController agendaController = _resolveAgendaController();
  late final GlobalVideoAdapterPool adapterPool =
      ensureGlobalVideoAdapterPool();
  final PlaybackRuntimeService _playbackRuntimeService =
      const PlaybackRuntimeService();
  final PlaybackExecutionService _playbackExecutionService =
      const PlaybackExecutionService();
  final SegmentCacheRuntimeService _segmentCacheRuntimeService =
      const SegmentCacheRuntimeService();
  PlaybackRuntimeService get playbackRuntimeService => _playbackRuntimeService;
  SegmentCacheRuntimeService get segmentCacheRuntimeService =>
      _segmentCacheRuntimeService;

  late final PostContentController controller;
  HLSVideoAdapter? _videoAdapter;
  bool _hasAutoPlayed = false;
  bool _manualPauseRequested = false;
  bool _skipNextPause = false;
  bool _blockPause = false;
  bool _replayOverlayLatched = false;
  bool _replayAdPrewarmed = false;
  bool _replayAdVisible = false;
  bool _replayButtonVisible = false;
  bool _replayAdImpressionReceived = false;
  bool _autoplayReplayInFlight = false;
  bool _surfaceKeepAliveDebounceActive = false;
  double? _lastAppliedPlaybackVolume;
  Timer? _replayAdHideTimer;
  Worker? _muteWorker;
  Worker? _pauseAllWorker;
  Worker? _playbackSuspendedWorker;
  Worker? _navSelectionWorker;
  Timer? _lazyInitTimer;
  Timer? _playbackRecoveryTimer;
  Timer? _autoplaySegmentGateTimer;
  Timer? _surfaceKeepAliveTimer;
  bool _playbackIntentTracked = false;
  DateTime? _autoplaySegmentGateStartedAt;
  bool _autoplaySegmentGateTimedOut = false;
  VoidCallback? _keepAliveUpdateCallback;

  /// Video state'i sadece süre/replay göstergesini güncellemek için.
  /// setState yerine ValueNotifier kullanarak tüm post'u rebuild etmekten kaçınıyoruz.
  final ValueNotifier<HLSVideoValue> videoValueNotifier =
      ValueNotifier(const HLSVideoValue());
  static const Duration _stableFramePositionThreshold =
      Duration(milliseconds: 180);
  static const Duration _autoplaySegmentGateTimeout =
      Duration(milliseconds: 950);
  static const Duration _autoplaySegmentGatePollInterval =
      Duration(milliseconds: 120);
  static const Duration _surfaceKeepAliveDebounce = Duration(milliseconds: 320);

  AgendaController _resolveAgendaController() {
    return ensureAgendaController();
  }

  /// videoController benzeri erişim — mevcut widget'lar uyumlu çalışır
  HLSVideoAdapter? get videoController => _videoAdapter;

  bool get isVideoFromCache {
    if (!widget.model.hasPlayableVideo) return false;
    try {
      return cachedSegmentCountForCurrentVideo > 0;
    } catch (_) {
      return false;
    }
  }

  int get cachedSegmentCountForCurrentVideo {
    if (!widget.model.hasPlayableVideo) return 0;
    try {
      return _segmentCacheRuntimeService.cachedSegmentCount(widget.model.docID);
    } catch (_) {
      return 0;
    }
  }

  /// 🎯 INSTAGRAM STYLE: Buffer BEKLEMEDEN direkt oynat
  bool get enableBufferedAutoplay => false;

  double get bufferedAutoplayThreshold => 0.10;

  /// Unique tag for GetX controller retrieval.
  String get controllerTag => widget.instanceTag ?? widget.model.docID;

  /// Playback handle identity must be unique per mounted video surface.
  /// Otherwise feed card and SinglePost can fight over the same player slot.
  String get playbackHandleKey {
    final instanceTag = widget.instanceTag?.trim() ?? '';
    if (instanceTag.isNotEmpty) return instanceTag;
    return 'feed:${widget.model.docID.trim()}';
  }

  bool get isStandalonePostInstance =>
      (widget.instanceTag ?? '').startsWith('single_');

  String get _surfaceInstanceTag => widget.instanceTag ?? '';

  bool get _isProfileSurfaceInstance =>
      _surfaceInstanceTag.startsWith('profile_');

  bool get _isFloodSurfaceInstance => _surfaceInstanceTag.startsWith('flood_');

  bool get _isExploreSeriesSurfaceInstance =>
      _surfaceInstanceTag.startsWith('explore_series_');

  bool get _isProfileFamilySurfaceInstance =>
      _surfaceInstanceTag.startsWith('profile_') ||
      _surfaceInstanceTag.startsWith('archives_') ||
      _surfaceInstanceTag.startsWith('liked_post_') ||
      _surfaceInstanceTag.startsWith('social_');

  bool get _isFeedStyleInlineSurfaceInstance =>
      _isPrimaryFeedSurfaceInstance ||
      _isProfileFamilySurfaceInstance ||
      _isFloodSurfaceInstance ||
      _isExploreSeriesSurfaceInstance;

  bool get _isPrimaryFeedSurfaceInstance =>
      !isStandalonePostInstance && _surfaceInstanceTag.isEmpty;

  bool get shouldKeepVideoSurfaceAlive =>
      widget.model.hasPlayableVideo &&
      (widget.shouldPlay || _surfaceKeepAliveDebounceActive);

  void bindKeepAliveUpdater(VoidCallback callback) {
    _keepAliveUpdateCallback = callback;
  }

  void _setSurfaceKeepAliveDebounce(bool value) {
    if (_surfaceKeepAliveDebounceActive == value) return;
    _surfaceKeepAliveDebounceActive = value;
    _keepAliveUpdateCallback?.call();
  }

  void _cancelSurfaceKeepAliveDebounce() {
    _surfaceKeepAliveTimer?.cancel();
    _surfaceKeepAliveTimer = null;
    _setSurfaceKeepAliveDebounce(false);
  }

  void _scheduleSurfaceKeepAliveDebounce() {
    if (!widget.model.hasPlayableVideo) return;
    _surfaceKeepAliveTimer?.cancel();
    _setSurfaceKeepAliveDebounce(true);
    _surfaceKeepAliveTimer = Timer(_surfaceKeepAliveDebounce, () {
      _surfaceKeepAliveTimer = null;
      _setSurfaceKeepAliveDebounce(false);
    });
  }

  bool get _useLegacyIosFeedBehavior =>
      defaultTargetPlatform == TargetPlatform.iOS &&
      !isStandalonePostInstance &&
      !_isFeedStyleInlineSurfaceInstance;

  bool get _isReplayOverlayEnabled =>
      !isStandalonePostInstance && !_useLegacyIosFeedBehavior;

  bool get isReplayOverlayBlockingTap =>
      _replayOverlayLatched || _replayAdVisible || _replayButtonVisible;

  bool get _controllerOwnsInlinePlayback =>
      !isStandalonePostInstance &&
      !_isFloodSurfaceInstance &&
      (_qaSurfaceName == 'feed' || _qaSurfaceName == 'profile');

  bool get shouldAutoResumeInlinePlatformView {
    if (isStandalonePostInstance) return widget.shouldPlay;
    if (_useLegacyIosFeedBehavior) return widget.shouldPlay;
    if (!widget.shouldPlay || !_isSurfacePlaybackAllowed) return false;
    if (_manualPauseRequested) return false;
    final adapter = _videoAdapter;
    if (adapter == null) return false;
    if (_playbackRuntimeService.currentPlayingDocId == playbackHandleKey) {
      return true;
    }
    final value = adapter.value;
    return value.isPlaying ||
        value.hasRenderedFirstFrame ||
        value.position > Duration.zero;
  }

  bool get _isSurfacePlaybackAllowed {
    if (_isFloodSurfaceInstance) {
      final route = ModalRoute.of(context);
      return route?.isCurrent ?? false;
    }
    if (_isExploreSeriesSurfaceInstance) {
      final nav = maybeFindNavBarController();
      if (nav != null) {
        return nav.selectedIndex.value == 1;
      }
      final route = Get.currentRoute.trim();
      return route == '/ExploreView' ||
          route == 'ExploreView' ||
          route == '/NavBarView' ||
          route == 'NavBarView';
    }
    if (isStandalonePostInstance) return true;
    if (_surfaceInstanceTag.startsWith('social_')) {
      final route = Get.currentRoute.trim();
      if (route == '/SocialProfile' || route == 'SocialProfile') {
        return true;
      }
    }
    if (!_isProfileFamilySurfaceInstance) {
      return agendaController.canClaimPlaybackNow;
    }
    final nav = maybeFindNavBarController();
    final settings = maybeFindSettingsController();
    final hasEducation = settings?.educationScreenIsOn.value ?? false;
    final profileIndex = hasEducation ? 4 : 3;
    return nav?.selectedIndex.value == profileIndex;
  }

  bool get shouldLoopVideo =>
      isStandalonePostInstance || _useLegacyIosFeedBehavior;

  String get _qaSurfaceName {
    if (isStandalonePostInstance) return 'feed';
    if (_isFloodSurfaceInstance) return 'flood';
    if (_isProfileFamilySurfaceInstance) return 'profile';
    return 'feed';
  }

  String get _qaScrollToken {
    if (_qaSurfaceName != 'feed') return '';
    return agendaController.latestQAScrollToken;
  }

  void _recordPlaybackDispatch(
    String stage, {
    String source = '',
    bool dispatchIssued = true,
    String skipReason = '',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    recordQALabPlaybackDispatch(
      surface: _qaSurfaceName,
      stage: stage,
      metadata: <String, dynamic>{
        'docId': widget.model.docID,
        'instanceTag': widget.instanceTag ?? '',
        'shouldPlay': widget.shouldPlay,
        'isStandalone': isStandalonePostInstance,
        'isProfileSurface': _isProfileSurfaceInstance,
        'isProfileFamilySurface': _isProfileFamilySurfaceInstance,
        'adapterInitialized': _videoAdapter?.value.isInitialized ?? false,
        'adapterPlaying': _videoAdapter?.value.isPlaying ?? false,
        'dispatchIssued': dispatchIssued,
        'dispatchSource': source,
        'callerSignature': source,
        'skipReason': skipReason,
        'scrollToken': _qaScrollToken,
        'currentPlayingDocId':
            _playbackRuntimeService.currentPlayingDocId ?? '',
        ...metadata,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _handleLifecycleInit();
  }

  void _initVideoController() {
    if (_videoAdapter != null) return;
    _lastAppliedPlaybackVolume = null;
    _videoAdapter = adapterPool.acquire(
      cacheKey: playbackHandleKey,
      url: widget.model.playbackUrl,
      // iOS feed, eski daha akıcı davranışı korusun; Android ise manual
      // dispatch ile çift-play dalgasından kaçınsın.
      autoPlay: _useLegacyIosFeedBehavior ? widget.shouldPlay : false,
      loop: shouldLoopVideo,
    );
    _playbackExecutionService.primeAdapter(_videoAdapter!);
    _videoAdapter!.hlsController.setTelemetryVideoId(widget.model.docID);

    _playbackRuntimeService.registerPlaybackHandle(
      playbackHandleKey,
      HLSAdapterPlaybackHandle(_videoAdapter!),
    );
    if (isStandalonePostInstance) {
      _playbackRuntimeService.enterExclusiveMode(playbackHandleKey);
    }

    _videoAdapter!.addListener(_onVideoUpdate);

    if (!isStandalonePostInstance) {
      _muteWorker = ever<bool>(agendaController.isMuted, (muted) {
        _applyPlaybackVolume();
      });
    } else {
      _applyPlaybackVolume();
      _syncRuntimeHints(isAudible: _resolvedPlaybackVolume() > 0);
    }

    if (!isStandalonePostInstance) {
      _pauseAllWorker = ever(agendaController.pauseAll, (value) {
        if (value == true) {
          _safePauseVideo();
        } else {
          if (_controllerOwnsInlinePlayback) return;
          _resumePlaybackIfEligible(source: 'pause_all_released');
        }
      });

      _playbackSuspendedWorker = ever<bool>(
        agendaController.playbackSuspended,
        (suspended) {
          if (suspended || !_isSurfacePlaybackAllowed) {
            if (suspended &&
                defaultTargetPlatform == TargetPlatform.iOS &&
                _isPrimaryFeedSurfaceInstance) {
              unawaited(_disposePlaybackForSurfaceLoss());
              return;
            }
            _stopPlaybackForSurfaceLoss();
          } else {
            if (_controllerOwnsInlinePlayback) return;
            _resumePlaybackIfEligible(source: 'playback_suspension_released');
          }
        },
      );

      final nav = maybeFindNavBarController();
      if (nav != null) {
        _navSelectionWorker = ever<int>(nav.selectedIndex, (_) {
          if (!_isSurfacePlaybackAllowed) {
            _stopPlaybackForSurfaceLoss();
          } else {
            _resumePlaybackIfEligible(source: 'nav_selection_changed');
          }
        });
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleDidChangeDependencies();
  }

  @override
  void dispose() {
    _handleLifecycleDispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleDidUpdateWidget(oldWidget);
  }

  @override
  void didPushNext() => _handleDidPushNext();

  @override
  void didPopNext() => _handleDidPopNext();

  @override
  void didPush() {
    _resumePlaybackIfEligible(source: 'route_did_push');
  }

  @override
  void didPop() {}

  void _onVideoUpdate() => _handleVideoUpdate();

  bool _hasStableVideoFrame(HLSVideoValue value) {
    return _playbackLifecycleDecision(value).hasStableVisualFrame;
  }

  PlaybackLifecycleDecision _playbackLifecycleDecision(
    HLSVideoValue value, {
    Duration visualReadyPositionThreshold = _stableFramePositionThreshold,
  }) {
    return _playbackRuntimeService.evaluateLifecycle(
      PlaybackLifecycleSnapshot(
        docId: playbackHandleKey,
        shouldPlay: widget.shouldPlay,
        isSurfacePlaybackAllowed: _isSurfacePlaybackAllowed,
        isStandalone: isStandalonePostInstance,
        isMuted: !isStandalonePostInstance && agendaController.isMuted.value,
        requiresReadySegment: widget.model.hasPlayableVideo,
        hasReadySegment:
            !widget.model.hasPlayableVideo || _hasReadyAutoplaySegment,
        isInitialized: value.isInitialized,
        isPlaying: value.isPlaying,
        isBuffering: value.isBuffering,
        isCompleted: value.isCompleted,
        hasRenderedFirstFrame: value.hasRenderedFirstFrame,
        position: value.position,
        duration: value.duration,
        visualReadyPositionThreshold: visualReadyPositionThreshold,
      ),
    );
  }

  bool shouldHidePlaybackPoster(
    HLSVideoValue value, {
    Duration visualReadyPositionThreshold = _stableFramePositionThreshold,
  }) {
    return _playbackLifecycleDecision(
      value,
      visualReadyPositionThreshold: visualReadyPositionThreshold,
    ).shouldHidePoster;
  }

  int _remainingSecondsBucket(HLSVideoValue value) {
    if (value.duration <= Duration.zero) return -1;
    final remaining = value.duration - value.position;
    final safeRemaining = remaining.isNegative ? Duration.zero : remaining;
    return safeRemaining.inSeconds;
  }

  bool _shouldSyncVideoNotifier(HLSVideoValue next) {
    final previous = videoValueNotifier.value;
    if (previous.isInitialized != next.isInitialized ||
        previous.isPlaying != next.isPlaying ||
        previous.isBuffering != next.isBuffering ||
        previous.isCompleted != next.isCompleted ||
        previous.hasRenderedFirstFrame != next.hasRenderedFirstFrame) {
      return true;
    }
    if (_hasStableVideoFrame(previous) != _hasStableVideoFrame(next)) {
      return true;
    }
    return _remainingSecondsBucket(previous) != _remainingSecondsBucket(next);
  }

  void _markPostContentDirty() {
    if (!mounted) return;
    setState(() {});
  }

  void onPostInitialized() {}
  void onPostFrameBound() {}
  Future<void> onReshareAdded(
    String? uid, {
    String? targetPostId,
  }) async {}
  Future<void> onReshareRemoved(
    String? uid, {
    String? targetPostId,
  }) async {}
}
