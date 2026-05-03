import 'dart:async';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Models/posts_model.dart';
import '../../../main.dart';
import '../../../hls_player/hls_video_adapter.dart';
import '../../../Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import '../../../Core/Services/feed_diversity_memory_service.dart';
import '../../../Core/Services/qa_lab_bridge.dart';
import '../../../Core/Services/video_telemetry_service.dart';
import '../../../Core/Services/playback_handle.dart';
import '../../../Core/Services/playback_execution_service.dart';
import '../../../Core/Services/global_video_adapter_pool.dart';
import '../../../Core/Services/video_state_manager.dart';
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

const int _feedWarmWindowAheadCount = 4;
const int _feedWarmWindowBehindCount = 2;
const int _feedStrongAheadCount = 5;
const int _feedStrongOppositeCount = 3;
const int _feedCacheOnlyOppositeCount = 2;
const int _androidPrimaryFeedNativeStrongAheadCount = 1;
const int _androidPrimaryFeedNativeStrongOppositeCount = 1;
const int _androidPrimaryFeedNativeCacheOnlyOppositeCount = 2;
const int _androidPrimaryFeedWarmPlayerAheadVideoCount = 1;
const int _androidProfileWarmPlayerAheadVideoCount = 1;
enum _FeedNativeWarmTier {
  off,
  cacheOnly,
  strong,
}

@visibleForTesting
({int start, int endExclusive}) resolveFeedSurfaceWarmRange({
  required int centeredIndex,
  required int listLength,
  int? previousCenteredIndex,
  int behindCount = _feedWarmWindowBehindCount,
  int aheadCount = _feedWarmWindowAheadCount,
}) {
  if (centeredIndex < 0 || listLength <= 0) {
    return (start: -1, endExclusive: -1);
  }
  final resolvedPrevious = previousCenteredIndex ?? centeredIndex;
  final directionalWindow = _resolveDirectionalFeedWarmWindowCounts(
    previousIndex: resolvedPrevious,
    currentIndex: centeredIndex,
    aheadCount: aheadCount,
    behindCount: behindCount,
  );
  final start = centeredIndex - directionalWindow.behindCount < 0
      ? 0
      : centeredIndex - directionalWindow.behindCount;
  final rawEndExclusive = centeredIndex + directionalWindow.aheadCount + 1;
  final endExclusive =
      rawEndExclusive > listLength ? listLength : rawEndExclusive;
  return (start: start, endExclusive: endExclusive);
}

({int aheadCount, int behindCount}) _resolveDirectionalFeedWarmWindowCounts({
  required int previousIndex,
  required int currentIndex,
  required int aheadCount,
  required int behindCount,
}) {
  if (currentIndex < previousIndex) {
    return (
      aheadCount: behindCount,
      behindCount: aheadCount,
    );
  }
  return (
    aheadCount: aheadCount,
    behindCount: behindCount,
  );
}

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
  String? _lastPlaybackVisualWarning;
  DateTime? _lastPlaybackVisualWarningAt;
  double? _lastAppliedPlaybackVolume;
  Timer? _replayAdHideTimer;
  Worker? _muteWorker;
  Worker? _pauseAllWorker;
  Worker? _playbackSuspendedWorker;
  Worker? _navSelectionWorker;
  Worker? _keepAliveWindowWorker;
  Worker? _warmPreloadAnchorWorker;
  Timer? _lazyInitTimer;
  Timer? _playbackRecoveryTimer;
  Timer? _stallWatchdogTimer;
  Timer? _autoplaySegmentGateTimer;
  Timer? _surfaceKeepAliveTimer;
  bool _playbackIntentTracked = false;
  bool _hasRecordedVisibleView = false;
  bool _feedRecoverInFlight = false;
  bool _warmPreloadInitQueued = false;
  bool _warmPreloadFetchClaimed = false;
  Duration? _lastQueuedSavedResumePosition;
  DateTime? _lastQueuedSavedResumeAt;
  DateTime? _savedResumeRecoveryGuardUntil;
  DateTime? _lastIosPrimaryFeedRecoveryAt;
  DateTime? _autoplaySegmentGateStartedAt;
  bool _autoplaySegmentGateTimedOut = false;
  Duration _stallWatchdogLastPosition = Duration.zero;
  int _stallWatchdogRetries = 0;
  int _stallWatchdogBufferingCycles = 0;
  bool _dependenciesReady = false;
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
      Duration(milliseconds: 80);
  static const Duration _surfaceKeepAliveDebounce = Duration(milliseconds: 320);
  static const Duration _resumeSurfaceKeepAliveDebounce =
      Duration(milliseconds: 720);
  static const Duration _androidFeedOwnerGrace = Duration(milliseconds: 1100);
  static const Duration _iosPrimaryFeedRecoveryCooldown =
      Duration(milliseconds: 2500);
  static const Duration _androidSavedResumeSeekCooldown =
      Duration(milliseconds: 2500);

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

  bool get isVideoFullyCached {
    if (!widget.model.hasPlayableVideo) return false;
    try {
      return _segmentCacheRuntimeService.isFullyCached(widget.model.docID);
    } catch (_) {
      return false;
    }
  }

  bool get isStartupCacheOriginVideo {
    if (!_isPrimaryFeedSurfaceInstance || !widget.model.hasPlayableVideo) {
      return false;
    }
    return agendaController.isStartupCacheOriginVideoDoc(widget.model.docID);
  }

  bool get shouldEnableStartupRecoveryWatchdog {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    if (_isPrimaryFeedSurfaceInstance) {
      // Feed already keeps a Flutter-side poster overlay and segment gate.
      // Native startup nudge/rebind recovery here adds churn and shows up as
      // startupSoftNudge on cold surface bring-up.
      return false;
    }
    return true;
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

  bool get _isSocialProfileSurfaceInstance =>
      _surfaceInstanceTag.startsWith('social_');

  bool get _isOwnProfileSurfaceInstance {
    if (_isProfileSurfaceInstance) return true;
    if (!_isSocialProfileSurfaceInstance) return false;
    return _resolveSocialProfileController()?.isOwnProfile ?? false;
  }

  SocialProfileController? _resolveSocialProfileController() {
    final reshareUserId = (widget.reshareUserID ?? '').trim();
    if (reshareUserId.isNotEmpty) {
      final byReshareUser =
          maybeFindSocialProfileController(tag: reshareUserId);
      if (byReshareUser != null) return byReshareUser;
    }
    final modelUserId = widget.model.userID.trim();
    if (modelUserId.isNotEmpty) {
      final byModelUser = maybeFindSocialProfileController(tag: modelUserId);
      if (byModelUser != null) return byModelUser;
    }
    return maybeFindSocialProfileController();
  }

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

  bool get isPrimaryFeedSurfaceInstance => _isPrimaryFeedSurfaceInstance;

  bool get _shouldPreserveIosPrimaryFeedPlaybackForResumeTransition {
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    if (!_isPrimaryFeedSurfaceInstance) return false;
    if (agendaController.playbackSuspended.value) return true;
    if (agendaController.centeredIndex.value != -1) return false;
    final modelIndex = _surfaceModelIndex();
    if (modelIndex < 0) return false;
    return agendaController.lastCenteredIndex == modelIndex;
  }

  void _recordVisibleViewIfNeeded() {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    if (_hasRecordedVisibleView) return;
    if (!widget.shouldPlay || !_isSurfacePlaybackAllowed) return;
    _hasRecordedVisibleView = true;
    unawaited(controller.saveSeeing());
  }

  bool get _shouldBypassLocalProxyForAndroidPrimaryFeed =>
      _isFloodSurfaceInstance;

  bool get shouldKeepVideoSurfaceAlive {
    if (defaultTargetPlatform == TargetPlatform.android &&
        (_isPrimaryFeedSurfaceInstance ||
            _isProfileSurfaceInstance ||
            _isSocialProfileSurfaceInstance) &&
        !widget.shouldPlay) {
      return false;
    }
    final keepAlive = widget.model.hasPlayableVideo &&
        (widget.shouldPlay ||
            _surfaceKeepAliveDebounceActive ||
            _shouldKeepPrimaryFeedSurfaceAliveInWarmWindow ||
            _shouldKeepProfileSurfaceAliveInWarmWindow ||
            _shouldKeepWarmSurfaceAliveForWarmPreload ||
            _shouldKeepFloodSurfaceAliveInWarmWindow);
    if (defaultTargetPlatform == TargetPlatform.android &&
        _isPrimaryFeedSurfaceInstance &&
        widget.model.hasPlayableVideo) {
      debugPrint(
        '[FeedSurfaceDecision] stage=should_keep_surface '
        'doc=${widget.model.docID} keepAlive=$keepAlive '
        'shouldPlay=${widget.shouldPlay} '
        'debounce=$_surfaceKeepAliveDebounceActive '
        'warmWindow=$_shouldKeepPrimaryFeedSurfaceAliveInWarmWindow '
        'warmPreload=$_shouldKeepWarmSurfaceAliveForWarmPreload '
        'adapterBound=${_videoAdapter != null}',
      );
    }
    return keepAlive;
  }

  bool get _shouldKeepWarmSurfaceAliveForWarmPreload =>
      _shouldPreloadWarmController;

  bool get _shouldKeepPrimaryFeedSurfaceAliveInWarmWindow {
    if (!_isPrimaryFeedSurfaceInstance) return false;
    if (!widget.model.hasPlayableVideo) return false;
    final modelIndex = agendaController.agendaList.indexWhere(
      (p) => p.docID == widget.model.docID,
    );
    if (modelIndex < 0) return false;
    final warmTier = _resolvePrimaryFeedNativeWarmTier(modelIndex: modelIndex);
    if (defaultTargetPlatform == TargetPlatform.android) {
      final keepAlive = _videoAdapter != null &&
          (warmTier == _FeedNativeWarmTier.strong ||
              warmTier == _FeedNativeWarmTier.cacheOnly);
      debugPrint(
        '[FeedSurfaceDecision] stage=warm_window '
        'doc=${widget.model.docID} keepAlive=$keepAlive '
        'modelIndex=$modelIndex centered=${_surfaceSafeCenteredIndex()} '
        'previousCentered=${_surfacePreviousCenteredIndex()} '
        'warmTier=${warmTier.name} adapterBound=${_videoAdapter != null}',
      );
      return keepAlive;
    }
    final value = _videoAdapter?.value ?? const HLSVideoValue();
    if (!value.hasRenderedFirstFrame) return false;
    final hasResumeHint = _hasResumePositionHint(
      value,
      threshold: _stableFramePositionThreshold,
    );
    if (!hasResumeHint) return false;
    return warmTier == _FeedNativeWarmTier.strong;
  }

  bool get _shouldKeepIosPrimaryFeedSurfaceAliveForBackScroll =>
      defaultTargetPlatform == TargetPlatform.iOS &&
      _shouldKeepPrimaryFeedSurfaceAliveInWarmWindow;

  bool get _shouldKeepAndroidPrimaryFeedSurfaceAliveForRebind =>
      defaultTargetPlatform == TargetPlatform.android &&
      _isPrimaryFeedSurfaceInstance &&
      _shouldKeepPrimaryFeedSurfaceAliveInWarmWindow;

  ({int start, int endExclusive}) _resolveFeedWarmRange({
    required int safeCenteredIndex,
    required int listLength,
  }) {
    return resolveFeedSurfaceWarmRange(
      centeredIndex: safeCenteredIndex,
      listLength: listLength,
      previousCenteredIndex: _surfacePreviousCenteredIndex(),
    );
  }

  bool get _shouldKeepFloodSurfaceAliveInWarmWindow {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    if (!_isFloodSurfaceInstance) return false;
    if (!widget.model.hasPlayableVideo) return false;
    final modelIndex = _surfaceModelIndex();
    if (modelIndex < 0) return false;
    final warmTier = _resolveDirectionalNativeWarmTier(
      modelIndex: modelIndex,
      centeredIndex: _surfaceSafeCenteredIndex(),
      previousCenteredIndex: _surfacePreviousCenteredIndex(),
    );
    return warmTier == _FeedNativeWarmTier.strong;
  }

  bool get _shouldKeepProfileSurfaceAliveInWarmWindow {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    if (!_isProfileSurfaceInstance && !_isSocialProfileSurfaceInstance) {
      return false;
    }
    if (!widget.model.hasPlayableVideo) return false;
    final value = _videoAdapter?.value ?? const HLSVideoValue();
    if (!value.hasRenderedFirstFrame) return false;
    final hasResumeHint = _hasResumePositionHint(
      value,
      threshold: _stableFramePositionThreshold,
    );
    if (!hasResumeHint) return false;
    final modelIndex = _surfaceModelIndex();
    if (modelIndex < 0) return false;
    final warmTier = _resolveDirectionalNativeWarmTier(
      modelIndex: modelIndex,
      centeredIndex: _surfaceSafeCenteredIndex(),
      previousCenteredIndex: _surfacePreviousCenteredIndex(),
    );
    return warmTier == _FeedNativeWarmTier.strong;
  }

  int _surfaceListLength() {
    if (_isFloodSurfaceInstance) {
      return maybeFindFloodListingController()?.floods.length ?? 0;
    }
    if (_isProfileSurfaceInstance) {
      return ProfileController.maybeFind()?.mergedPosts.length ?? 0;
    }
    if (_isSocialProfileSurfaceInstance) {
      return _resolveSocialProfileController()?.combinedFeedEntries.length ?? 0;
    }
    return agendaController.agendaList.length;
  }

  int _surfaceModelIndex() {
    if (_isFloodSurfaceInstance) {
      return maybeFindFloodListingController()?.floods.indexWhere(
                (p) => p.docID == widget.model.docID,
              ) ??
          -1;
    }
    if (_isProfileSurfaceInstance) {
      final profileController = ProfileController.maybeFind();
      if (profileController == null) return -1;
      return profileController.indexOfMergedEntry(
        docId: widget.model.docID,
        isReshare: widget.isReshared,
      );
    }
    if (_isSocialProfileSurfaceInstance) {
      final socialProfileController = _resolveSocialProfileController();
      if (socialProfileController == null) return -1;
      return socialProfileController.indexOfCombinedEntry(
        docId: widget.model.docID,
        isReshare: widget.isReshared,
      );
    }
    return agendaController.agendaList.indexWhere(
      (p) => p.docID == widget.model.docID,
    );
  }

  int _surfaceCurrentCenteredIndex() {
    if (_isFloodSurfaceInstance) {
      return maybeFindFloodListingController()?.centeredIndex.value ?? -1;
    }
    if (_isProfileSurfaceInstance) {
      return ProfileController.maybeFind()?.centeredIndex.value ?? -1;
    }
    if (_isSocialProfileSurfaceInstance) {
      return _resolveSocialProfileController()?.centeredIndex.value ?? -1;
    }
    return agendaController.centeredIndex.value;
  }

  int _surfaceSafeCenteredIndex() {
    final length = _surfaceListLength();
    if (length <= 0) return -1;
    final centered = _surfaceCurrentCenteredIndex();
    if (centered < 0) return -1;
    return centered.clamp(0, length - 1);
  }

  int? _surfacePreviousCenteredIndex() {
    if (_isFloodSurfaceInstance) {
      return maybeFindFloodListingController()?.lastCenteredIndex;
    }
    if (_isProfileSurfaceInstance) {
      return ProfileController.maybeFind()?.lastCenteredIndex;
    }
    if (_isSocialProfileSurfaceInstance) {
      return _resolveSocialProfileController()?.lastCenteredIndex;
    }
    return agendaController.lastCenteredIndex;
  }

  String _currentCenteredFeedPlaybackHandleKey() {
    if (!_isPrimaryFeedSurfaceInstance) return '';
    final safeCentered = _surfaceSafeCenteredIndex();
    if (safeCentered < 0 ||
        safeCentered >= agendaController.agendaList.length) {
      return '';
    }
    final centeredDocId =
        agendaController.agendaList[safeCentered].docID.trim();
    if (centeredDocId.isEmpty) return '';
    return 'feed:$centeredDocId';
  }

  bool get _isCenteredFeedWarmPreloadAnchorReady {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    if (!_isPrimaryFeedSurfaceInstance) return false;
    final centeredPlaybackKey = _currentCenteredFeedPlaybackHandleKey();
    if (centeredPlaybackKey.isEmpty) return false;
    return agendaController.feedWarmPreloadAnchorKey == centeredPlaybackKey;
  }

  bool _surfaceEntryHasPlayableVideo(int index) {
    if (index < 0) return false;
    if (_isFloodSurfaceInstance) {
      final posts = maybeFindFloodListingController()?.floods;
      if (posts == null || index >= posts.length) return false;
      return posts[index].hasPlayableVideo;
    }
    if (_isProfileSurfaceInstance) {
      final entries = ProfileController.maybeFind()?.mergedPosts;
      if (entries == null || index >= entries.length) return false;
      final post = entries[index]['post'];
      return post is PostsModel &&
          post.hasPlayableVideo &&
          !post.deletedPost &&
          !post.arsiv;
    }
    if (_isSocialProfileSurfaceInstance) {
      final entries = _resolveSocialProfileController()?.combinedFeedEntries;
      if (entries == null || index >= entries.length) return false;
      final post = entries[index]['post'];
      return post is PostsModel &&
          post.hasPlayableVideo &&
          !post.deletedPost &&
          !post.arsiv;
    }
    if (index >= agendaController.agendaList.length) return false;
    return agendaController.agendaList[index].hasPlayableVideo;
  }

  int? _surfaceDirectionalAheadPlayableVideoDistance() {
    if (!widget.model.hasPlayableVideo) return null;
    final modelIndex = _surfaceModelIndex();
    final safeCentered = _surfaceSafeCenteredIndex();
    if (modelIndex < 0 || safeCentered < 0) return null;
    if (modelIndex == safeCentered) return 0;
    final previousCentered = _surfacePreviousCenteredIndex() ?? safeCentered;
    final scrollingBackward = safeCentered < previousCentered;
    if (!scrollingBackward && modelIndex < safeCentered) return null;
    if (scrollingBackward && modelIndex > safeCentered) return null;

    int playableDistance = 0;
    if (!scrollingBackward) {
      for (int i = safeCentered + 1; i <= modelIndex; i++) {
        if (_surfaceEntryHasPlayableVideo(i)) {
          playableDistance++;
        }
      }
    } else {
      for (int i = safeCentered - 1; i >= modelIndex; i--) {
        if (_surfaceEntryHasPlayableVideo(i)) {
          playableDistance++;
        }
      }
    }
    return playableDistance;
  }

  String _feedPlaybackOffsetLabel() {
    if (!_isPrimaryFeedSurfaceInstance) return 'non_feed';
    final modelIndex = _surfaceModelIndex();
    final centered = _surfaceSafeCenteredIndex();
    if (modelIndex < 0 || centered < 0) return 'unknown';
    if (modelIndex == centered) return '0';
    final distance = _surfaceDirectionalAheadPlayableVideoDistance();
    if (distance == null) {
      final rawDelta = modelIndex - centered;
      return rawDelta > 0 ? '+$rawDelta(raw)' : '$rawDelta(raw)';
    }
    final previousCentered = _surfacePreviousCenteredIndex() ?? centered;
    final scrollingBackward = centered < previousCentered;
    final sign = scrollingBackward ? '-' : '+';
    return '$sign$distance';
  }

  _FeedNativeWarmTier _resolvePrimaryFeedNativeWarmTier({
    required int modelIndex,
  }) {
    return _resolveDirectionalNativeWarmTier(
      modelIndex: modelIndex,
      centeredIndex: _surfaceSafeCenteredIndex(),
      previousCenteredIndex: _surfacePreviousCenteredIndex(),
    );
  }

  _FeedNativeWarmTier _resolveDirectionalNativeWarmTier({
    required int modelIndex,
    required int centeredIndex,
    required int? previousCenteredIndex,
  }) {
    if (modelIndex < 0 || centeredIndex < 0) {
      return _FeedNativeWarmTier.off;
    }
    final delta = modelIndex - centeredIndex;
    if (delta == 0) {
      return _FeedNativeWarmTier.strong;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        _isPrimaryFeedSurfaceInstance) {
      return _FeedNativeWarmTier.off;
    }
    final previous = previousCenteredIndex ?? centeredIndex;
    final scrollingBackward = centeredIndex < previous;
    final isMotionSide = scrollingBackward ? delta < 0 : delta > 0;
    final distance = delta.abs();
    final isAndroidPrimaryFeed =
        defaultTargetPlatform == TargetPlatform.android &&
            _isPrimaryFeedSurfaceInstance;
    final strongAheadCount = isAndroidPrimaryFeed
        ? _androidPrimaryFeedNativeStrongAheadCount
        : _feedStrongAheadCount;
    final strongOppositeCount = isAndroidPrimaryFeed
        ? _androidPrimaryFeedNativeStrongOppositeCount
        : _feedStrongOppositeCount;
    final cacheOnlyOppositeCount = isAndroidPrimaryFeed
        ? _androidPrimaryFeedNativeCacheOnlyOppositeCount
        : _feedCacheOnlyOppositeCount;
    if (isMotionSide) {
      return distance <= strongAheadCount
          ? _FeedNativeWarmTier.strong
          : _FeedNativeWarmTier.off;
    }
    if (distance <= strongOppositeCount) {
      return _FeedNativeWarmTier.strong;
    }
    if (distance <= strongOppositeCount + cacheOnlyOppositeCount) {
      return _FeedNativeWarmTier.cacheOnly;
    }
    return _FeedNativeWarmTier.off;
  }

  bool get _shouldPreloadWarmController {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final isIosPrimaryFeed = defaultTargetPlatform == TargetPlatform.iOS &&
        _isPrimaryFeedSurfaceInstance;
    if (!isAndroid && !isIosPrimaryFeed) return false;
    if (isIosPrimaryFeed) {
      return false;
    }
    // Keep native warm controller preload limited to the primary feed.
    // Profile/social surfaces still use segment/cache warming, but should not
    // initialize off-screen players that can render an unexpected first frame.
    final isSupportedSurface =
        _isPrimaryFeedSurfaceInstance || _isFloodSurfaceInstance;
    if (!isSupportedSurface) return false;
    if (!widget.model.hasPlayableVideo) return false;
    if (widget.shouldPlay) return false;
    if (!_isSurfacePlaybackAllowed) return false;
    if (isAndroid &&
        _isPrimaryFeedSurfaceInstance &&
        !_isCenteredFeedWarmPreloadAnchorReady) {
      return false;
    }
    if (isAndroid && _isFloodSurfaceInstance) {
      final modelIndex = _surfaceModelIndex();
      if (modelIndex < 0) return false;
      final warmTier = _resolveDirectionalNativeWarmTier(
        modelIndex: modelIndex,
        centeredIndex: _surfaceSafeCenteredIndex(),
        previousCenteredIndex: _surfacePreviousCenteredIndex(),
      );
      if (warmTier != _FeedNativeWarmTier.strong) return false;
      return true;
    }
    if (_isPrimaryFeedSurfaceInstance) {
      final modelIndex = _surfaceModelIndex();
      if (modelIndex >= 0) {
        final warmTier = _resolvePrimaryFeedNativeWarmTier(
          modelIndex: modelIndex,
        );
        if (warmTier == _FeedNativeWarmTier.strong) {
          debugPrint(
            '[FeedSurfaceDecision] stage=warm_preload_gate '
            'doc=${widget.model.docID} allow=true reason=strong_warm_tier '
            'modelIndex=$modelIndex centered=${_surfaceSafeCenteredIndex()} '
            'previousCentered=${_surfacePreviousCenteredIndex()} '
            'adapterBound=${_videoAdapter != null}',
          );
          return true;
        }
      }
    }
    final playableDistance = _surfaceDirectionalAheadPlayableVideoDistance();
    if (playableDistance == null || playableDistance <= 0) return false;
    final maxAheadPlayableCount = _isPrimaryFeedSurfaceInstance
        ? _androidPrimaryFeedWarmPlayerAheadVideoCount
        : _androidProfileWarmPlayerAheadVideoCount;
    return playableDistance <= maxAheadPlayableCount;
  }

  RxInt _surfaceCenteredIndexSignal() {
    if (_isFloodSurfaceInstance) {
      return maybeFindFloodListingController()?.centeredIndex ??
          agendaController.centeredIndex;
    }
    if (_isProfileSurfaceInstance) {
      return ProfileController.maybeFind()?.centeredIndex ??
          agendaController.centeredIndex;
    }
    if (_isSocialProfileSurfaceInstance) {
      return _resolveSocialProfileController()?.centeredIndex ??
          agendaController.centeredIndex;
    }
    return agendaController.centeredIndex;
  }

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
    final debounce = _shouldKeepPrimaryFeedSurfaceAliveInWarmWindow
        ? _resumeSurfaceKeepAliveDebounce
        : _surfaceKeepAliveDebounce;
    _surfaceKeepAliveTimer = Timer(debounce, () {
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

  bool get _shouldAutorestartCompletedPlayback =>
      !_isReplayOverlayEnabled && !shouldLoopVideo;

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
      if (!_dependenciesReady) {
        return true;
      }
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
    _warmPreloadInitQueued = false;
    _lastAppliedPlaybackVolume = null;
    _videoAdapter = adapterPool.acquire(
      cacheKey: playbackHandleKey,
      url: widget.model.playbackUrl,
      // iOS feed, eski daha akıcı davranışı korusun; Android ise manual
      // dispatch ile çift-play dalgasından kaçınsın.
      autoPlay: _useLegacyIosFeedBehavior ? widget.shouldPlay : false,
      loop: shouldLoopVideo,
      useLocalProxy: !_shouldBypassLocalProxyForAndroidPrimaryFeed,
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
    _keepAliveUpdateCallback?.call();
    _markPostContentDirty();

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
                _shouldPreserveIosPrimaryFeedPlaybackForResumeTransition) {
              _safePauseVideo();
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
    _dependenciesReady = true;
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
    final ownerGrace = defaultTargetPlatform == TargetPlatform.android &&
            _isPrimaryFeedSurfaceInstance
        ? _androidFeedOwnerGrace
        : const Duration(milliseconds: 650);
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
      ownerGrace: ownerGrace,
    );
  }

  bool _hasResumePositionHint(
    HLSVideoValue value, {
    required Duration threshold,
    String? source,
  }) {
    if (_shouldBypassSavedResumeHintForPrimaryFeed(
      value,
      source: source,
    )) {
      return false;
    }
    if (value.position > threshold) return true;
    final savedState =
        playbackRuntimeService.getSavedPlaybackState(playbackHandleKey);
    return (savedState?.position ?? Duration.zero) > threshold;
  }

  bool _shouldBypassSavedResumeHintForPrimaryFeed(
    HLSVideoValue value, {
    String? source,
  }) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return !_isPrimaryFeedSurfaceInstance;
    }
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    if (!_isPrimaryFeedSurfaceInstance) return false;
    if (_isExplicitResumeRecoveryContext(value, source: source)) return false;
    if (!isStartupCacheOriginVideo) return false;
    final modelIndex = agendaController.agendaList.indexWhere(
      (p) => p.docID == widget.model.docID,
    );
    return modelIndex == 0;
  }

  bool _isExplicitResumeRecoveryContext(
    HLSVideoValue value, {
    String? source,
  }) {
    if (source?.contains('route_did_pop_next') ?? false) return true;
    if (value.awaitingFreshFrameAfterReattach) return true;
    final adapter = _videoAdapter;
    if (adapter == null) return false;
    return adapter.hlsController.awaitingFreshFrameAfterReattach;
  }

  bool shouldHidePlaybackPoster(
    HLSVideoValue value, {
    Duration visualReadyPositionThreshold = _stableFramePositionThreshold,
  }) {
    final shouldPinPosterWhileInactive = !isStandalonePostInstance &&
        (!widget.shouldPlay || !_isSurfacePlaybackAllowed);
    if (shouldPinPosterWhileInactive) {
      return false;
    }
    if (defaultTargetPlatform == TargetPlatform.android &&
        _isPrimaryFeedSurfaceInstance) {
      if (value.hasRenderedFirstFrame &&
          widget.shouldPlay &&
          _isSurfacePlaybackAllowed) {
        return true;
      }
    }
    return _playbackLifecycleDecision(
      value,
      visualReadyPositionThreshold: visualReadyPositionThreshold,
    ).shouldHidePoster;
  }

  bool get shouldSuppressGenericResumeThumbnail {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    if (!_isPrimaryFeedSurfaceInstance) return false;
    return false;
  }

  String _resolvePlaybackVisualWarning(
    HLSVideoValue value, {
    Duration visualReadyPositionThreshold = _stableFramePositionThreshold,
    String source = 'video_update',
  }) {
    final hasResumeHint = _hasResumePositionHint(
      value,
      threshold: visualReadyPositionThreshold,
      source: source,
    );
    final pinnedPoster = !isStandalonePostInstance &&
        (!widget.shouldPlay || !_isSurfacePlaybackAllowed);
    if (pinnedPoster) {
      return hasResumeHint ? 'resume_poster' : 'poster';
    }

    final hasStableVideo = value.hasRenderedFirstFrame &&
        widget.shouldPlay &&
        _isSurfacePlaybackAllowed;
    if (hasStableVideo) return 'video_play';

    if (hasResumeHint) {
      return 'resume_poster';
    }

    final shouldHidePoster = shouldHidePlaybackPoster(
      value,
      visualReadyPositionThreshold: visualReadyPositionThreshold,
    );
    if (!shouldHidePoster) {
      return 'thumb';
    }

    return 'siyah';
  }

  void _recordPlaybackVisualWarning(
    HLSVideoValue value, {
    String source = 'video_update',
  }) {
    if (!widget.model.hasPlayableVideo) return;
    final next = _resolvePlaybackVisualWarning(value, source: source);
    final now = DateTime.now();
    final previousWarning = _lastPlaybackVisualWarning;
    final previousWarningStartedAt = _lastPlaybackVisualWarningAt;
    if (_lastPlaybackVisualWarning == next) return;
    _lastPlaybackVisualWarning = next;
    _lastPlaybackVisualWarningAt = now;
    final safeCenteredIndex = _surfaceSafeCenteredIndex();
    final warmRange = _isFloodSurfaceInstance
        ? resolveFeedSurfaceWarmRange(
            centeredIndex: safeCenteredIndex,
            listLength: _surfaceListLength(),
            previousCenteredIndex: _surfacePreviousCenteredIndex(),
          )
        : _resolveFeedWarmRange(
            safeCenteredIndex: safeCenteredIndex,
            listLength: _surfaceListLength(),
          );
    final warmWindowStart = warmRange.start;
    final warmWindowEndExclusive = warmRange.endExclusive;
    final modelIndex = _surfaceModelIndex();
    final previousCenteredIndex = _surfacePreviousCenteredIndex();
    final distanceFromCenter = modelIndex >= 0 && safeCenteredIndex >= 0
        ? modelIndex - safeCenteredIndex
        : null;
    final nativeWarmTier = modelIndex >= 0 && safeCenteredIndex >= 0
        ? _resolveDirectionalNativeWarmTier(
            modelIndex: modelIndex,
            centeredIndex: safeCenteredIndex,
            previousCenteredIndex: previousCenteredIndex,
          )
        : _FeedNativeWarmTier.off;
    final metadata = <String, dynamic>{
      'docId': widget.model.docID,
      'instanceTag': widget.instanceTag ?? '',
      'playbackHandleKey': playbackHandleKey,
      'surface': _qaSurfaceName,
      'warning': next,
      'source': source,
      'previousWarning': previousWarning ?? '',
      'previousWarningDurationMs': previousWarningStartedAt == null
          ? -1
          : now.difference(previousWarningStartedAt).inMilliseconds,
      'phaseStartedAtEpochMs': now.millisecondsSinceEpoch,
      'shouldPlay': widget.shouldPlay,
      'surfaceAllowed': _isSurfacePlaybackAllowed,
      'positionMs': value.position.inMilliseconds,
      'durationMs': value.duration.inMilliseconds,
      'isInitialized': value.isInitialized,
      'isPlaying': value.isPlaying,
      'isBuffering': value.isBuffering,
      'hasRenderedFirstFrame': value.hasRenderedFirstFrame,
      'awaitingFreshFrameAfterReattach': value.awaitingFreshFrameAfterReattach,
      'resumeHint': _hasResumePositionHint(
        value,
        threshold: _stableFramePositionThreshold,
        source: source,
      ),
      'centeredIndex': safeCenteredIndex,
      'previousCenteredIndex': previousCenteredIndex,
      'modelIndex': modelIndex,
      'distanceFromCenter': distanceFromCenter,
      'nativeWarmTier': nativeWarmTier.name,
      'warmWindowStart': warmWindowStart,
      'warmWindowEndExclusive': warmWindowEndExclusive,
      'insideWarmWindow': modelIndex >= 0 &&
          warmWindowStart >= 0 &&
          modelIndex >= warmWindowStart &&
          modelIndex < warmWindowEndExclusive,
    };
    if (kDebugMode) {
      debugPrint(
        '[PlaybackVisual][$next][${widget.model.docID}] source=$source metadata=$metadata',
      );
    }
    recordQALabVideoEvent(
      code: 'playback_visual_$next',
      message: 'playback visual phase changed',
      metadata: metadata,
    );
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
