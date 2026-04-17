import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/hls_segment_policy.dart';
import 'package:turqappv2/Core/Services/SegmentCache/models.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/playback_handle.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';

typedef SegmentCacheEntryReader = VideoCacheEntry? Function(String docId);
typedef SegmentCacheDocAction = void Function(String docId);
typedef SegmentCacheProgressAction = void Function(
    String docId, double progress);
typedef SegmentCacheReadySegmentsAction = void Function(
    String docId, int readySegments);

enum PlaybackLifecyclePhase {
  blocked,
  background,
  waitingForSegment,
  waitingForPlayer,
  waitingForFirstFrame,
  waitingForVisualSync,
  audible,
}

class PlaybackLifecycleSnapshot {
  const PlaybackLifecycleSnapshot({
    required this.docId,
    required this.shouldPlay,
    required this.isSurfacePlaybackAllowed,
    required this.isStandalone,
    required this.isMuted,
    required this.requiresReadySegment,
    required this.hasReadySegment,
    required this.isInitialized,
    required this.isPlaying,
    required this.isBuffering,
    required this.isCompleted,
    required this.hasRenderedFirstFrame,
    required this.position,
    required this.duration,
    this.visualReadyPositionThreshold = const Duration(milliseconds: 450),
    this.playbackEndGrace = const Duration(milliseconds: 350),
  });

  final String docId;
  final bool shouldPlay;
  final bool isSurfacePlaybackAllowed;
  final bool isStandalone;
  final bool isMuted;
  final bool requiresReadySegment;
  final bool hasReadySegment;
  final bool isInitialized;
  final bool isPlaying;
  final bool isBuffering;
  final bool isCompleted;
  final bool hasRenderedFirstFrame;
  final Duration position;
  final Duration duration;
  final Duration visualReadyPositionThreshold;
  final Duration playbackEndGrace;
}

class PlaybackLifecycleDecision {
  const PlaybackLifecycleDecision({
    required this.phase,
    required this.isOwnerCandidate,
    required this.hasStableVisualFrame,
    required this.shouldHidePoster,
    required this.shouldBeAudible,
  });

  final PlaybackLifecyclePhase phase;
  final bool isOwnerCandidate;
  final bool hasStableVisualFrame;
  final bool shouldHidePoster;
  final bool shouldBeAudible;
}

class PlaybackRuntimeService {
  const PlaybackRuntimeService({
    this.managerProvider,
  });

  final VideoStateManager Function()? managerProvider;

  VideoStateManager get _manager =>
      (managerProvider ?? _defaultManagerProvider).call();

  static VideoStateManager _defaultManagerProvider() {
    return resolveDefaultVideoStateManager();
  }

  String? get currentPlayingDocId => _manager.currentPlayingDocID;

  void pauseAll({bool force = false}) {
    _manager.pauseAllVideos(force: force);
  }

  void playOnlyThis(String docId) {
    _manager.playOnlyThis(docId);
  }

  void requestPlay(String docId, PlaybackHandle handle) {
    _manager.requestPlayVideo(docId, handle);
  }

  void requestStop(String docId) {
    _manager.requestStopVideo(docId);
  }

  void registerPlaybackHandle(String docId, PlaybackHandle handle) {
    _manager.registerPlaybackHandle(docId, handle);
  }

  void unregisterPlaybackHandle(String docId) {
    _manager.unregisterVideoController(docId);
  }

  void savePlaybackState(String docId, PlaybackHandle handle) {
    _manager.saveVideoState(docId, handle);
  }

  VideoState? getSavedPlaybackState(String docId) {
    return _manager.getVideoState(docId);
  }

  void clearSavedPlaybackState(String docId) {
    _manager.clearVideoState(docId);
  }

  void enterExclusiveMode(String docId) {
    _manager.enterExclusiveMode(docId);
  }

  void updateExclusiveModeDoc(String docId) {
    _manager.updateExclusiveModeDoc(docId);
  }

  void exitExclusiveMode() {
    _manager.exitExclusiveMode();
  }

  bool hasPendingPlayFor(String docId) {
    return _manager.hasPendingPlayFor(docId);
  }

  bool shouldKeepAudiblePlayback(
    String docId, {
    Duration grace = const Duration(milliseconds: 650),
  }) {
    return _manager.shouldKeepAudiblePlayback(docId, grace: grace);
  }

  PlaybackLifecycleDecision evaluateLifecycle(
    PlaybackLifecycleSnapshot snapshot, {
    Duration ownerGrace = const Duration(milliseconds: 650),
  }) {
    final trimmedDocId = snapshot.docId.trim();
    final isOwnerCandidate = snapshot.isStandalone ||
        shouldKeepAudiblePlayback(trimmedDocId, grace: ownerGrace);
    final atPlaybackEnd = snapshot.isCompleted ||
        (snapshot.duration > Duration.zero &&
            snapshot.position >=
                (snapshot.duration - snapshot.playbackEndGrace));
    final reachedStablePlaybackPosition =
        snapshot.position > snapshot.visualReadyPositionThreshold;
    final hasAudiblePlaybackFrame = atPlaybackEnd ||
        (snapshot.hasRenderedFirstFrame &&
            !snapshot.isBuffering &&
            (snapshot.isPlaying || reachedStablePlaybackPosition));
    final hasStableVisualFrame = atPlaybackEnd ||
        (snapshot.hasRenderedFirstFrame &&
            !snapshot.isBuffering &&
            reachedStablePlaybackPosition);

    final phase = !snapshot.shouldPlay || !snapshot.isSurfacePlaybackAllowed
        ? PlaybackLifecyclePhase.blocked
        : !isOwnerCandidate
            ? PlaybackLifecyclePhase.background
            : (snapshot.requiresReadySegment && !snapshot.hasReadySegment)
                ? PlaybackLifecyclePhase.waitingForSegment
                : !snapshot.isInitialized
                    ? PlaybackLifecyclePhase.waitingForPlayer
                    : (!snapshot.hasRenderedFirstFrame && !atPlaybackEnd)
                        ? PlaybackLifecyclePhase.waitingForFirstFrame
                        : !hasAudiblePlaybackFrame
                            ? PlaybackLifecyclePhase.waitingForVisualSync
                            : PlaybackLifecyclePhase.audible;

    final shouldBeAudible =
        !snapshot.isMuted && isOwnerCandidate && hasAudiblePlaybackFrame;

    return PlaybackLifecycleDecision(
      phase: phase,
      isOwnerCandidate: isOwnerCandidate,
      hasStableVisualFrame: hasStableVisualFrame,
      shouldHidePoster: hasStableVisualFrame,
      shouldBeAudible: shouldBeAudible,
    );
  }

  bool resumeCurrentPlaybackIfReady(String docId) {
    return _manager.resumeCurrentPlaybackIfReady(docId);
  }
}

class SegmentCacheRuntimeService {
  const SegmentCacheRuntimeService({
    this.entryReader,
    this.markPlayingAction,
    this.touchEntryAction,
    this.touchUserEntryAction,
    this.updateWatchProgressAction,
    this.boostReadySegmentsAction,
  });

  final SegmentCacheEntryReader? entryReader;
  final SegmentCacheDocAction? markPlayingAction;
  final SegmentCacheDocAction? touchEntryAction;
  final SegmentCacheDocAction? touchUserEntryAction;
  final SegmentCacheProgressAction? updateWatchProgressAction;
  final SegmentCacheReadySegmentsAction? boostReadySegmentsAction;

  static const int globalReadySegmentCount = 2;
  static const int globalWatchLookAheadSegments = 2;

  static final Map<String, int> _lastRequestedReadySegmentsByDoc =
      <String, int>{};

  VideoCacheEntry? _readEntry(String docId) {
    final reader = entryReader;
    if (reader != null) {
      return reader(docId);
    }
    final cache = maybeFindSegmentCacheManager();
    if (cache == null || !cache.isReady) return null;
    return cache.getEntry(docId);
  }

  void _markPlaying(String docId) {
    final action = markPlayingAction;
    if (action != null) {
      action(docId);
      return;
    }
    final cache = maybeFindSegmentCacheManager();
    if (cache == null || !cache.isReady) return;
    cache.markPlaying(docId);
  }

  void _touchEntry(String docId) {
    final action = touchEntryAction;
    if (action != null) {
      action(docId);
      return;
    }
    final cache = maybeFindSegmentCacheManager();
    if (cache == null || !cache.isReady) return;
    cache.touchEntry(docId);
  }

  void _touchUserEntry(String docId) {
    final action = touchUserEntryAction;
    if (action != null) {
      action(docId);
      return;
    }
    final cache = maybeFindSegmentCacheManager();
    if (cache == null || !cache.isReady) return;
    cache.touchUserEntry(docId);
  }

  void _updateWatchProgress(String docId, double progress) {
    final action = updateWatchProgressAction;
    if (action != null) {
      action(docId, progress);
      return;
    }
    final cache = maybeFindSegmentCacheManager();
    if (cache == null || !cache.isReady) return;
    cache.updateWatchProgress(docId, progress);
  }

  int cachedSegmentCount(String docId) {
    return _readEntry(docId)?.cachedSegmentCount ?? 0;
  }

  bool isFullyCached(String docId) {
    return _readEntry(docId)?.isFullyCached ?? false;
  }

  bool hasReadySegment(
    String docId, {
    int minimumSegmentCount = 1,
  }) {
    return cachedSegmentCount(docId) >= minimumSegmentCount;
  }

  VideoCacheEntry? getEntry(String docId) {
    final normalizedDocId = HlsSegmentPolicy.normalizeDocId(docId);
    if (normalizedDocId == null) return null;
    final cache = maybeFindSegmentCacheManager();
    if (cache == null || !cache.isReady) return null;
    return cache.getEntry(normalizedDocId);
  }

  int? estimateCurrentSegmentForDoc(
    String docId, {
    required double progress,
    double? positionSeconds,
  }) {
    final normalizedDocId = HlsSegmentPolicy.normalizeDocId(docId);
    if (normalizedDocId == null) return null;
    final entry = _readEntry(normalizedDocId);
    if (entry == null) return null;
    final totalSegmentCount = entry.totalSegmentCount;
    if (totalSegmentCount <= 0) return null;
    if (positionSeconds != null) {
      return HlsSegmentPolicy.estimateCurrentSegment(
        positionSeconds: positionSeconds,
        totalSegments: totalSegmentCount,
      );
    }
    return _estimateCurrentSegment(
      progress: progress.clamp(0.0, 1.0),
      totalSegments: totalSegmentCount,
    );
  }

  void ensureMinimumReadySegments(
    String docId, {
    int minimumSegmentCount = globalReadySegmentCount,
  }) {
    final normalizedDocId = HlsSegmentPolicy.normalizeDocId(docId);
    if (normalizedDocId == null) return;
    final targetReadySegments = minimumSegmentCount.clamp(1, 99);
    final entry = _readEntry(normalizedDocId);
    if (entry != null && entry.cachedSegmentCount >= targetReadySegments) {
      final lastRequested =
          _lastRequestedReadySegmentsByDoc[normalizedDocId] ?? 0;
      if (lastRequested <= entry.cachedSegmentCount) {
        _lastRequestedReadySegmentsByDoc.remove(normalizedDocId);
      }
      return;
    }

    final lastRequested =
        _lastRequestedReadySegmentsByDoc[normalizedDocId] ?? 0;
    if (targetReadySegments <= lastRequested &&
        lastRequested > (entry?.cachedSegmentCount ?? 0)) {
      return;
    }

    final boostAction = boostReadySegmentsAction;
    if (boostAction != null) {
      _lastRequestedReadySegmentsByDoc[normalizedDocId] = targetReadySegments;
      boostAction(normalizedDocId, targetReadySegments);
      return;
    }
    final scheduler = maybeFindPrefetchScheduler();
    if (scheduler == null) return;
    _lastRequestedReadySegmentsByDoc[normalizedDocId] = targetReadySegments;
    scheduler.boostDoc(normalizedDocId, readySegments: targetReadySegments);
  }

  void markPlaying(String docId) {
    _markPlaying(docId);
  }

  void touchEntry(String docId) {
    _touchEntry(docId);
  }

  void touchUserEntry(String docId) {
    _touchUserEntry(docId);
  }

  void updateWatchProgress(String docId, double progress) {
    _updateWatchProgress(docId, progress);
  }

  void markServedInShort(String docId) {
    final normalizedDocId = HlsSegmentPolicy.normalizeDocId(docId);
    if (normalizedDocId == null) return;
    final cache = maybeFindSegmentCacheManager();
    if (cache == null || !cache.isReady) return;
    cache.markServedInShort(normalizedDocId);
  }

  void markServedInFeed(String docId) {
    final normalizedDocId = HlsSegmentPolicy.normalizeDocId(docId);
    if (normalizedDocId == null) return;
    final cache = maybeFindSegmentCacheManager();
    if (cache == null || !cache.isReady) return;
    cache.markServedInFeed(normalizedDocId);
  }

  void markShortConsumed(String docId) {
    final normalizedDocId = HlsSegmentPolicy.normalizeDocId(docId);
    if (normalizedDocId == null) return;
    final cache = maybeFindSegmentCacheManager();
    if (cache == null || !cache.isReady) return;
    cache.markShortConsumed(normalizedDocId);
  }

  void scheduleDrainAfterPlayback(String docId) {
    final normalizedDocId = HlsSegmentPolicy.normalizeDocId(docId);
    if (normalizedDocId == null) return;
    final cache = maybeFindSegmentCacheManager();
    if (cache == null || !cache.isReady) return;
    cache.scheduleDrainAfterPlayback(normalizedDocId);
  }

  void ensureNextSegmentReady(
    String docId,
    double progress, {
    int lookAheadSegments = globalWatchLookAheadSegments,
    double? positionSeconds,
  }) {
    final normalizedDocId = HlsSegmentPolicy.normalizeDocId(docId);
    if (normalizedDocId == null) return;
    final normalized = progress.clamp(0.0, 1.0);
    if (normalized <= 0) return;
    final entry = _readEntry(normalizedDocId);
    if (entry == null) return;

    final totalSegmentCount = entry.totalSegmentCount;
    if (totalSegmentCount <= 1) return;

    final currentSegment = positionSeconds != null
        ? HlsSegmentPolicy.estimateCurrentSegment(
            positionSeconds: positionSeconds,
            totalSegments: totalSegmentCount,
          )
        : _estimateCurrentSegment(
            progress: normalized,
            totalSegments: totalSegmentCount,
          );
    final targetReadySegments =
        (currentSegment + lookAheadSegments).clamp(1, totalSegmentCount);

    if (entry.cachedSegmentCount >= targetReadySegments) {
      final lastRequested =
          _lastRequestedReadySegmentsByDoc[normalizedDocId] ?? 0;
      if (lastRequested <= entry.cachedSegmentCount) {
        _lastRequestedReadySegmentsByDoc.remove(normalizedDocId);
      }
      return;
    }

    final lastRequested =
        _lastRequestedReadySegmentsByDoc[normalizedDocId] ?? 0;
    if (targetReadySegments <= lastRequested &&
        lastRequested > entry.cachedSegmentCount) {
      return;
    }

    final boostAction = boostReadySegmentsAction;
    if (boostAction != null) {
      _lastRequestedReadySegmentsByDoc[normalizedDocId] = targetReadySegments;
      boostAction(normalizedDocId, targetReadySegments);
      return;
    }
    final scheduler = maybeFindPrefetchScheduler();
    if (scheduler == null) return;
    _lastRequestedReadySegmentsByDoc[normalizedDocId] = targetReadySegments;
    scheduler.boostDoc(normalizedDocId, readySegments: targetReadySegments);
  }

  void markPlayingAndTouchRecent(
    List<String> orderedDocIds,
    int currentIndex, {
    int lookBehind = 5,
  }) {
    if (currentIndex < 0 || currentIndex >= orderedDocIds.length) return;

    markPlaying(orderedDocIds[currentIndex]);
    for (var i = 1; i <= lookBehind; i++) {
      final behindIndex = currentIndex - i;
      if (behindIndex < 0 || behindIndex >= orderedDocIds.length) {
        break;
      }
      touchUserEntry(orderedDocIds[behindIndex]);
    }
  }

  int _estimateCurrentSegment({
    required double progress,
    required int totalSegments,
  }) {
    return HlsSegmentPolicy.estimateCurrentSegmentFromProgress(
      progress: progress,
      totalSegments: totalSegments,
    );
  }
}
