import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/hls_cache_path.dart';
import 'package:turqappv2/Core/Services/SegmentCache/hls_proxy_server.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/Modules/PlaybackRuntime/playback_cache_runtime_service.dart';
import 'package:turqappv2/hls_player/hls_player_module.dart'; // ✅ HLS PLAYER
import '../StoryMaker/story_maker_controller.dart';
import 'package:turqappv2/main.dart';

class StoryVideoWidget extends StatefulWidget {
  final String storyId;
  final StoryElement element;
  final Function(Duration actualDuration) onStarted;
  final VoidCallback onEnded;
  final Duration maxDuration;
  final bool paused;

  const StoryVideoWidget({
    super.key,
    required this.storyId,
    required this.element,
    required this.onStarted,
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
  bool _fetchOwnershipClaimed = false;

  bool get _effectivePaused => widget.paused || _routePaused;
  String get _playbackUrl {
    final canonicalUrl = canonicalizeHlsCdnUrl(widget.element.content);
    final proxy = maybeFindHlsProxyServer();
    if (proxy == null) return canonicalUrl;
    return proxy.resolveUrl(canonicalUrl);
  }

  @override
  void initState() {
    super.initState();
    _seedStoryCacheEntry();
    _syncFetchOwnership();
    // ✅ HLS Player event listener
    _hlsStateSub = _hlsController.onStateChanged.listen((state) {
      if (!mounted) return;

      if (state == PlayerState.ready) {
        if (!_hlsReady) {
          setState(() {
            _hlsReady = true;
          });
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
      final positionSeconds = position.inMilliseconds / 1000.0;
      final progress = (positionSeconds / durationSeconds).clamp(0.0, 1.0);
      if (progress <= 0) return;
      try {
        _segmentCacheRuntimeService.ensureNextSegmentReady(
          widget.storyId,
          progress,
          positionSeconds: positionSeconds,
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
      cache.cacheHlsEntry(widget.storyId, widget.element.content);
    } catch (_) {}
  }

  void _claimFetchOwnership([String? storyId]) {
    if (_fetchOwnershipClaimed) return;
    VideoStateManager.instance.claimExternalOnDemandFetch(
      storyId ?? widget.storyId,
    );
    _fetchOwnershipClaimed = true;
  }

  void _releaseFetchOwnership([String? storyId]) {
    if (!_fetchOwnershipClaimed) return;
    maybeFindVideoStateManager()?.releaseExternalOnDemandFetch(
      storyId ?? widget.storyId,
    );
    _fetchOwnershipClaimed = false;
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

  Future<void> _stopForOffscreen() async {
    _releaseFetchOwnership();
    _offscreenResumePositionSeconds = _hlsController.currentPosition;
    if (_hlsReady && mounted) {
      setState(() {
        _hlsReady = false;
      });
    } else {
      _hlsReady = false;
    }
    await _hlsController.stopPlayback();
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
      if (oldWidget.storyId != widget.storyId) {
        _releaseFetchOwnership(oldWidget.storyId);
      }
      _seedStoryCacheEntry();
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
    unawaited(_stopForOffscreen());
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
    unawaited(_stopForOffscreen());
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
        ),
        if (!_hlsReady)
          const Center(
            child: CupertinoActivityIndicator(color: Colors.grey),
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
