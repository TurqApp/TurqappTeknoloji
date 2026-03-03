import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoControllerPool {
  static final _pool = <String, HLSVideoAdapter>{};
  static final _order = <String>[];

  static String _poolKey(String url, bool coordinateAudioFocus) =>
      '$url|af:${coordinateAudioFocus ? 1 : 0}';

  static HLSVideoAdapter getController(
    String url, {
    bool coordinateAudioFocus = true,
  }) {
    final key = _poolKey(url, coordinateAudioFocus);
    if (_pool.containsKey(key)) return _pool[key]!;

    if (_pool.length >= 20) {
      final oldest = _order.removeAt(0);
      _pool[oldest]?.dispose();
      _pool.remove(oldest);
    }

    final adapter = HLSVideoAdapter(
      url: url,
      autoPlay: true,
      loop: true,
      coordinateAudioFocus: coordinateAudioFocus,
    );
    _pool[key] = adapter;
    _order.add(key);
    return adapter;
  }

  static Future<void> release(
    String url, {
    bool coordinateAudioFocus = true,
  }) async {
    final key = _poolKey(url, coordinateAudioFocus);
    if (_pool.containsKey(key)) {
      _pool[key]?.pause();
      _pool[key]?.dispose();
      _pool.remove(key);
      _order.remove(key);
    }
  }

  static Future<void> pauseAll() async {
    for (final adapter in _pool.values) {
      try {
        await adapter.pause();
      } catch (_) {}
    }
  }
}

class SmartMiniVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;
  final bool muted;
  final String visibilityKey;
  final double aspectRatio;
  final bool useAspectRatio;

  const SmartMiniVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.visibilityKey,
    this.muted = true,
    this.aspectRatio = 16 / 9,
    this.useAspectRatio = false,
  });

  @override
  State<SmartMiniVideoPlayer> createState() => _SmartMiniVideoPlayerState();
}

class _SmartMiniVideoPlayerState extends State<SmartMiniVideoPlayer>
    with WidgetsBindingObserver {
  static const int _previewLoopMs = 1900;
  HLSVideoAdapter? _adapter;
  bool isVisible = false;
  bool _seekingToStart = false;

  void _onAdapterTick() {
    final a = _adapter;
    if (a == null) return;
    if (_seekingToStart) return;
    if (!a.value.isPlaying) return;

    final durationMs = a.value.duration.inMilliseconds;
    final loopCutoff = durationMs > 0
        ? durationMs.clamp(700, _previewLoopMs)
        : _previewLoopMs;

    // Preview'de sadece ilk segment döngüsü (yaklaşık 2 sn)
    if (a.value.position.inMilliseconds >= loopCutoff) {
      _seekingToStart = true;
      a.seekTo(Duration.zero).then((_) => a.play()).whenComplete(() {
        Future.delayed(const Duration(milliseconds: 120), () {
          _seekingToStart = false;
        });
      });
    }
  }

  void _initController() {
    _adapter = VideoControllerPool.getController(
      widget.videoUrl,
      coordinateAudioFocus: false,
    );
    _adapter?.removeListener(_onAdapterTick);
    _adapter?.addListener(_onAdapterTick);
    _adapter?.setVolume(widget.muted ? 0.0 : 1.0);
    _adapter?.seekTo(Duration.zero).then((_) => _adapter?.play());
    if (mounted) setState(() {});
  }

  Future<void> _disposeController() async {
    if (_adapter != null) {
      _adapter?.removeListener(_onAdapterTick);
      await VideoControllerPool.release(
        widget.videoUrl,
        coordinateAudioFocus: false,
      );
      _adapter = null;
      if (mounted) setState(() {});
    }
  }

  Future<void> _softHoldController() async {
    if (_adapter != null) {
      _adapter?.removeListener(_onAdapterTick);
      await _adapter?.pause();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_adapter == null) return;
    if (state == AppLifecycleState.resumed && isVisible) {
      _adapter?.setVolume(widget.muted ? 0.0 : 1.0);
      _adapter?.play();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _adapter?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.visibilityKey),
      onVisibilityChanged: (info) {
        final v = info.visibleFraction;
        if (v > 0.08 && !isVisible) {
          isVisible = true;
          _initController();
        } else if (v < 0.005 && isVisible) {
          isVisible = false;
          _softHoldController();
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: _adapter != null
            ? _adapter!.buildPlayer(
                aspectRatio: widget.aspectRatio,
                useAspectRatio: widget.useAspectRatio,
              )
            : SizedBox.expand(
                child: CachedNetworkImage(
                  imageUrl: widget.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(color: Colors.black12),
                  errorWidget: (c, u, e) =>
                      const Icon(Icons.image_not_supported),
                ),
              ),
      ),
    );
  }
}
