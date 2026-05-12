import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/hls_cache_path.dart';
import 'package:turqappv2/Core/Services/SegmentCache/hls_segment_policy.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/Modules/PlaybackRuntime/playback_cache_runtime_service.dart';
import 'package:turqappv2/hls_player/hls_player_module.dart'; // ✅ HLS PLAYER
import '../StoryMaker/story_maker_controller.dart';
import 'package:turqappv2/main.dart';

typedef StoryVideoStopCallback = Future<void> Function(String reason);

class StoryVideoPlaybackRegistry {
  StoryVideoPlaybackRegistry._();

  static final Map<String, StoryVideoStopCallback> _stopCallbacks =
      <String, StoryVideoStopCallback>{};

  static void register(String key, StoryVideoStopCallback callback) {
    final normalized = key.trim();
    if (normalized.isEmpty) return;
    _stopCallbacks[normalized] = callback;
  }

  static void unregister(String key, StoryVideoStopCallback callback) {
    final normalized = key.trim();
    if (normalized.isEmpty) return;
    if (!identical(_stopCallbacks[normalized], callback)) return;
    _stopCallbacks.remove(normalized);
  }

  static Future<bool> stop(String key, {required String reason}) async {
    final normalized = key.trim();
    if (normalized.isEmpty) return false;
    final callback = _stopCallbacks[normalized];
    if (callback == null) return false;
    await callback(reason);
    return true;
  }
}

class StoryVideoWidget extends StatefulWidget {
  final String storyId;
  final StoryElement element;
  final Function(Duration actualDuration) onStarted;
  final ValueChanged<double>? onProgress;
  final VoidCallback onEnded;
  final Duration maxDuration;
  final bool paused;

  const StoryVideoWidget({
    super.key,
    required this.storyId,
    required this.element,
    required this.onStarted,
    this.onProgress,
    required this.onEnded,
    required this.maxDuration,
    this.paused = false,
  });

  @override
  State<StoryVideoWidget> createState() => _StoryVideoWidgetState();
}

class _StoryVideoWidgetState extends State<StoryVideoWidget> with RouteAware {
  final HLSController _hlsController = HLSController(); // ✅ HLS CONTROLLER
  final SegmentCacheRuntimeService _segmentCacheRuntimeService =
      const SegmentCacheRuntimeService();

  bool _notifiedStarted = false;
  bool _notifiedEnded = false;
  bool _hlsReady = false;
  bool _routePaused = false;
  Timer? _maxTimer;
  StreamSubscription? _hlsStateSub;
  StreamSubscription<Duration>? _hlsPositionSub;
  double? _offscreenResumePositionSeconds;
  String? _claimedFetchDocId;
  bool _loggedPositionStartFallback = false;
  bool _stoppingForOffscreen = false;
  int? _lastLoggedReadySegmentTarget;
  late final StoryVideoStopCallback _externalStopCallback = _handleExternalStop;

  bool get _effectivePaused => widget.paused || _routePaused;
  String get _mediaDocId => _mediaDocIdFor(widget);

  String _mediaDocIdFor(StoryVideoWidget widget) {
    return hlsDocIdFromUrlOrPath(widget.element.content) ?? widget.storyId;
  }

  String get _playbackUrl {
    return canonicalizeHlsCdnUrl(widget.element.content);
  }

  @override
  void initState() {
    super.initState();
    _seedStoryCacheEntry();
    _registerStopCallbacks();
    _syncFetchOwnership();
    // ✅ HLS Player event listener
    _hlsStateSub = _hlsController.onStateChanged.listen((state) {
      if (!mounted) return;

      if (state == PlayerState.ready || state == PlayerState.playing) {
        if (!_hlsReady) {
          setState(() {
            _hlsReady = true;
          });
          debugPrint(
            '[StoryVideoVisual] action=ready_from_state '
            'state=$state story=${widget.storyId} mediaDoc=$_mediaDocId',
          );
          _onHLSReady(_hlsController.duration);
        }
      } else if (state == PlayerState.completed) {
        _onHLSEnded();
      }
    });
    _hlsPositionSub = _hlsController.onPositionChanged.listen((position) {
      if (!mounted) return;
      final durationSeconds = _hlsController.duration;
      if (!durationSeconds.isFinite || durationSeconds <= 0) return;
      if (!_hlsReady && position.inMilliseconds > 0) {
        setState(() {
          _hlsReady = true;
        });
        debugPrint(
          '[StoryVideoVisual] action=ready_from_position '
          'story=${widget.storyId} mediaDoc=$_mediaDocId '
          'positionMs=${position.inMilliseconds} '
          'durationMs=${(durationSeconds * 1000).round()}',
        );
      }
      if (!_notifiedStarted) {
        if (!_loggedPositionStartFallback) {
          _loggedPositionStartFallback = true;
          debugPrint(
            '[StoryVideoProgress] action=start_from_position '
            'story=${widget.storyId} mediaDoc=$_mediaDocId '
            'positionMs=${position.inMilliseconds} '
            'durationMs=${(durationSeconds * 1000).round()}',
          );
        }
        _notifyStarted(
          Duration(milliseconds: (durationSeconds * 1000).toInt()),
        );
      }
      final positionSeconds = position.inMilliseconds / 1000.0;
      final effectiveDurationSeconds =
          durationSeconds > widget.maxDuration.inMilliseconds / 1000.0
              ? widget.maxDuration.inMilliseconds / 1000.0
              : durationSeconds;
      final progress =
          (positionSeconds / effectiveDurationSeconds).clamp(0.0, 1.0);
      if (progress <= 0) return;
      widget.onProgress?.call(progress);
      try {
        final currentSegment =
            _segmentCacheRuntimeService.estimateCurrentSegmentForDoc(
          widget.storyId,
          progress: progress,
          positionSeconds: positionSeconds,
          firstSegmentSeconds: HlsSegmentPolicy.storyFirstSegmentSeconds,
          nextSegmentSeconds: HlsSegmentPolicy.storyNextSegmentSeconds,
        );
        if (currentSegment != null) {
          final targetReadySegments = currentSegment + 1;
          if (_lastLoggedReadySegmentTarget != targetReadySegments) {
            _lastLoggedReadySegmentTarget = targetReadySegments;
            debugPrint(
              '[StorySegmentWarm] action=ensure_next story=${widget.storyId} '
              'mediaDoc=$_mediaDocId currentSegment=$currentSegment '
              'targetReadySegments=$targetReadySegments '
              'segmentFirstSec=${HlsSegmentPolicy.storyFirstSegmentSeconds} '
              'segmentNextSec=${HlsSegmentPolicy.storyNextSegmentSeconds} '
              'positionMs=${position.inMilliseconds} '
              'progress=${progress.toStringAsFixed(3)}',
            );
          }
        }
        _segmentCacheRuntimeService.ensureNextSegmentReady(
          widget.storyId,
          progress,
          lookAheadSegments: 1,
          positionSeconds: positionSeconds,
          firstSegmentSeconds: HlsSegmentPolicy.storyFirstSegmentSeconds,
          nextSegmentSeconds: HlsSegmentPolicy.storyNextSegmentSeconds,
        );
      } catch (_) {}
      try {
        _segmentCacheRuntimeService.updateWatchProgress(
          widget.storyId,
          progress,
        );
      } catch (_) {}
    });
  }

  void _seedStoryCacheEntry() {
    try {
      final cache = maybeFindSegmentCacheManager();
      if (cache == null || !cache.isReady) return;
      cache.cacheHlsEntry(_mediaDocId, widget.element.content);
    } catch (_) {}
  }

  void _claimFetchOwnership([String? docId]) {
    final resolvedDocId = (docId ?? _mediaDocId).trim();
    if (resolvedDocId.isEmpty) return;
    if (_claimedFetchDocId == resolvedDocId) return;
    _releaseFetchOwnership();
    claimExternalOnDemandFetchForDoc(resolvedDocId);
    _claimedFetchDocId = resolvedDocId;
    debugPrint(
      '[StoryVideoFetch] action=claim story=${widget.storyId} mediaDoc=$resolvedDocId',
    );
  }

  void _registerStopCallbacks() {
    StoryVideoPlaybackRegistry.register(widget.storyId, _externalStopCallback);
    StoryVideoPlaybackRegistry.register(_mediaDocId, _externalStopCallback);
  }

  void _unregisterStopCallbacks({
    String? storyId,
    String? mediaDocId,
  }) {
    StoryVideoPlaybackRegistry.unregister(
      storyId ?? widget.storyId,
      _externalStopCallback,
    );
    StoryVideoPlaybackRegistry.unregister(
      mediaDocId ?? _mediaDocId,
      _externalStopCallback,
    );
  }

  Future<void> _handleExternalStop(String reason) {
    return _stopForOffscreen(reason: reason);
  }

  void _releaseFetchOwnership([String? docId]) {
    final resolvedDocId = (docId ?? _claimedFetchDocId)?.trim();
    if (resolvedDocId == null || resolvedDocId.isEmpty) return;
    releaseExternalOnDemandFetchForDoc(resolvedDocId);
    if (_claimedFetchDocId == resolvedDocId) {
      _claimedFetchDocId = null;
    }
    debugPrint(
      '[StoryVideoFetch] action=release story=${widget.storyId} mediaDoc=$resolvedDocId',
    );
  }

  void _syncFetchOwnership() {
    if (_effectivePaused || _notifiedEnded) {
      _releaseFetchOwnership();
      return;
    }
    _claimFetchOwnership();
  }

  void _notifyStarted(Duration actualDuration) {
    if (_notifiedStarted) return;
    _notifiedStarted = true;

    final effectiveDuration = actualDuration > widget.maxDuration
        ? widget.maxDuration
        : actualDuration;
    widget.onStarted(effectiveDuration);

    if (actualDuration > widget.maxDuration) {
      _maxTimer?.cancel();
      _maxTimer = Timer(widget.maxDuration, () {
        if (!mounted) return;
        unawaited(_stopForOffscreen());
        _emitEnded();
      });
    }
  }

  void _emitEnded() {
    if (_notifiedEnded) return;
    _notifiedEnded = true;
    _maxTimer?.cancel();
    _releaseFetchOwnership();
    widget.onEnded();
  }

  void _onHLSReady(double durationSeconds) {
    if (!mounted) return;
    _notifyStarted(Duration(milliseconds: (durationSeconds * 1000).toInt()));
  }

  void _onHLSEnded() {
    _emitEnded();
  }

  Future<void> _stopForOffscreen({
    String reason = 'offscreen',
    bool preserveFrameSnapshot = false,
  }) async {
    if (_stoppingForOffscreen) return;
    _stoppingForOffscreen = true;
    try {
      _releaseFetchOwnership();
      _offscreenResumePositionSeconds = _hlsController.currentPosition;
      if (_hlsReady && mounted) {
        setState(() {
          _hlsReady = false;
        });
      } else {
        _hlsReady = false;
      }
      debugPrint(
        '[StoryPlaybackStop] action=stop_start story=${widget.storyId} '
        'mediaDoc=$_mediaDocId reason=$reason '
        'positionMs=${(_offscreenResumePositionSeconds ?? 0) * 1000 ~/ 1} '
        'preserveFrameSnapshot=$preserveFrameSnapshot',
      );
      await _hlsController.stopPlayback(
        preserveFrameSnapshot: preserveFrameSnapshot,
      );
      debugPrint(
        '[StoryPlaybackStop] action=stop_done story=${widget.storyId} '
        'mediaDoc=$_mediaDocId reason=$reason',
      );
    } finally {
      _stoppingForOffscreen = false;
    }
  }

  Future<void> _restartAfterOffscreen() async {
    _syncFetchOwnership();
    final resumeAt = _offscreenResumePositionSeconds;
    _offscreenResumePositionSeconds = null;
    _hlsReady = false;
    if (mounted) {
      setState(() {});
    }
    await _hlsController.loadVideo(
      _playbackUrl,
      autoPlay: false,
      loop: false,
    );
    if (resumeAt != null && resumeAt > 0.05) {
      await _hlsController.seekTo(resumeAt);
    }
    if (!_effectivePaused && !_notifiedEnded) {
      await _hlsController.play();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _hlsStateSub?.cancel();
    _hlsPositionSub?.cancel();
    _unregisterStopCallbacks();
    _releaseFetchOwnership();
    _hlsController.dispose();
    _maxTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StoryVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.content != widget.element.content ||
        oldWidget.storyId != widget.storyId) {
      final oldMediaDocId = _mediaDocIdFor(oldWidget);
      _unregisterStopCallbacks(
        storyId: oldWidget.storyId,
        mediaDocId: oldMediaDocId,
      );
      if (oldMediaDocId != _mediaDocId) {
        _releaseFetchOwnership(oldMediaDocId);
      }
      _seedStoryCacheEntry();
      _lastLoggedReadySegmentTarget = null;
      _registerStopCallbacks();
    }
    if (oldWidget.element.isMuted != widget.element.isMuted) {
      _hlsController.setMuted(widget.element.isMuted);
    }
    if (oldWidget.paused != widget.paused) {
      if (_effectivePaused) {
        _hlsController.pause();
      } else {
        _hlsController.play();
      }
    }
    _syncFetchOwnership();
  }

  @override
  void didPushNext() {
    _routePaused = true;
    unawaited(_stopForOffscreen(
      reason: 'route_push_next',
      preserveFrameSnapshot: false,
    ));
  }

  @override
  void didPopNext() {
    _routePaused = false;
    _syncFetchOwnership();
    if (!_effectivePaused && !_notifiedEnded) {
      unawaited(_restartAfterOffscreen());
    }
  }

  void pause() {
    unawaited(_stopForOffscreen(
      reason: 'pause_api',
      preserveFrameSnapshot: false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final child = Stack(
      children: [
        // ✅ HLS PLAYER
        HLSPlayer(
          url: _playbackUrl,
          controller: _hlsController,
          autoPlay: !_effectivePaused,
          loop: false,
          showControls: false,
          aspectRatio: widget.element.width / widget.element.height,
          useAspectRatio: false,
        ),
        if (!_hlsReady && widget.element.posterUrl.trim().isNotEmpty)
          Positioned.fill(
            child: CachedNetworkImage(
              cacheManager: TurqImageCacheManager.instance,
              imageUrl: widget.element.posterUrl.trim(),
              fit: BoxFit.cover,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (context, url) => const SizedBox.expand(),
              errorWidget: (context, url, error) => const SizedBox.expand(),
            ),
          ),
      ],
    );

    return Positioned(
      left: widget.element.position.dx,
      top: widget.element.position.dy,
      width: widget.element.width,
      height: widget.element.height,
      child: Transform.rotate(
        angle: widget.element.rotation,
        child: child,
      ),
    );
  }
}
