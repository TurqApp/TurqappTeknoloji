import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/models.dart';
import 'package:turqappv2/Core/Services/playback_handle.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';

typedef SegmentCacheEntryReader = VideoCacheEntry? Function(String docId);
typedef SegmentCacheDocAction = void Function(String docId);
typedef SegmentCacheProgressAction = void Function(
    String docId, double progress);

class PlaybackRuntimeService {
  const PlaybackRuntimeService({
    this.managerProvider,
  });

  final VideoStateManager Function()? managerProvider;

  VideoStateManager get _manager =>
      (managerProvider ?? _defaultManagerProvider).call();

  static VideoStateManager _defaultManagerProvider() {
    return VideoStateManager.instance;
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

  bool resumeCurrentPlaybackIfReady(String docId) {
    return _manager.resumeCurrentPlaybackIfReady(docId);
  }
}

class SegmentCacheRuntimeService {
  const SegmentCacheRuntimeService({
    this.entryReader,
    this.markPlayingAction,
    this.touchEntryAction,
    this.updateWatchProgressAction,
  });

  final SegmentCacheEntryReader? entryReader;
  final SegmentCacheDocAction? markPlayingAction;
  final SegmentCacheDocAction? touchEntryAction;
  final SegmentCacheProgressAction? updateWatchProgressAction;

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

  bool hasReadySegment(
    String docId, {
    int minimumSegmentCount = 1,
  }) {
    return cachedSegmentCount(docId) >= minimumSegmentCount;
  }

  void markPlaying(String docId) {
    _markPlaying(docId);
  }

  void touchEntry(String docId) {
    _touchEntry(docId);
  }

  void updateWatchProgress(String docId, double progress) {
    _updateWatchProgress(docId, progress);
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
      touchEntry(orderedDocIds[behindIndex]);
    }
  }
}
