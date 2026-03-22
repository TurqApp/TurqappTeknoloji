import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/hls_player/hls_player_module.dart'; // ✅ HLS PLAYER
import '../StoryMaker/story_maker_controller.dart';
import 'package:turqappv2/main.dart';

class StoryVideoWidget extends StatefulWidget {
  final StoryElement element;
  final Function(Duration actualDuration) onStarted;
  final VoidCallback onEnded;
  final Duration maxDuration;
  final bool paused;

  const StoryVideoWidget({
    super.key,
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

  bool _notifiedStarted = false;
  bool _notifiedEnded = false;
  bool _hlsReady = false;
  bool _routePaused = false;
  Timer? _maxTimer;
  StreamSubscription? _hlsStateSub;

  bool get _effectivePaused => widget.paused || _routePaused;

  @override
  void initState() {
    super.initState();
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
        _hlsController.pause();
        _emitEnded();
      });
    }
  }

  void _emitEnded() {
    if (_notifiedEnded) return;
    _notifiedEnded = true;
    _maxTimer?.cancel();
    widget.onEnded();
  }

  void _onHLSReady(double durationSeconds) {
    if (!mounted) return;
    _notifyStarted(Duration(milliseconds: (durationSeconds * 1000).toInt()));
  }

  void _onHLSEnded() {
    _emitEnded();
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
    _hlsController.dispose();
    _maxTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StoryVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
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
  }

  @override
  void didPushNext() {
    _routePaused = true;
    _hlsController.pause();
  }

  @override
  void didPopNext() {
    _routePaused = false;
    if (!_effectivePaused && !_notifiedEnded) {
      _hlsController.play();
    }
  }

  void pause() {
    _hlsController.pause();
  }

  @override
  Widget build(BuildContext context) {
    final child = Stack(
      children: [
        // ✅ HLS PLAYER
        HLSPlayer(
          url: widget.element.content,
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
