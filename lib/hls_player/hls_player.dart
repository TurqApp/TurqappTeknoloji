import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'hls_controller.dart';

class HLSPlayer extends StatefulWidget {
  final String url;
  final HLSController controller;
  final bool autoPlay;
  final bool loop;
  final bool showControls;
  final Color? backgroundColor;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final BoxFit fit;
  final double aspectRatio;
  final bool useAspectRatio;

  const HLSPlayer({
    super.key,
    required this.url,
    required this.controller,
    this.autoPlay = true,
    this.loop = false,
    this.showControls = true,
    this.backgroundColor,
    this.loadingWidget,
    this.errorWidget,
    this.fit = BoxFit.contain,
    this.aspectRatio = 16 / 9,
    this.useAspectRatio = true,
  });

  @override
  State<HLSPlayer> createState() => _HLSPlayerState();
}

class _HLSPlayerState extends State<HLSPlayer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(HLSPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload video if URL changed
    if (oldWidget.url != widget.url && _isInitialized) {
      _loadVideo();
    }

    // Update loop if changed
    if (oldWidget.loop != widget.loop && _isInitialized) {
      widget.controller.setLoop(widget.loop);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onPlatformViewCreated(int viewId) {
    _isInitialized = true;
    widget.controller.initialize(viewId);
  }

  Future<void> _loadVideo() async {
    await widget.controller.loadVideo(
      widget.url,
      autoPlay: widget.autoPlay,
      loop: widget.loop,
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerBody = Container(
      color: widget.backgroundColor ?? Colors.transparent,
      child: Stack(
        children: [
          // Platform view
          if (Platform.isIOS)
            _buildIOSPlayer()
          else if (Platform.isAndroid)
            _buildAndroidPlayer()
          else
            _buildUnsupportedPlatform(),

          // Loading indicator
          StreamBuilder<PlayerState>(
            stream: widget.controller.onStateChanged,
            initialData: widget.controller.state,
            builder: (context, snapshot) {
              final state = snapshot.data ?? PlayerState.idle;

              if (state == PlayerState.loading) {
                return Center(
                  child: widget.loadingWidget ??
                      const CircularProgressIndicator(
                        color: Colors.white,
                      ),
                );
              }

              return const SizedBox.shrink();
            },
          ),

          // Error widget
          StreamBuilder<PlayerState>(
            stream: widget.controller.onStateChanged,
            initialData: widget.controller.state,
            builder: (context, snapshot) {
              final state = snapshot.data ?? PlayerState.idle;

              if (state == PlayerState.error) {
                return Center(
                  child: widget.errorWidget ??
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.controller.errorMessage ?? 'Video yüklenemedi',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                );
              }

              return const SizedBox.shrink();
            },
          ),

          // Controls overlay
          if (widget.showControls)
            Positioned.fill(
              child: _HLSPlayerControls(controller: widget.controller),
            ),
        ],
      ),
    );

    if (!widget.useAspectRatio) {
      return SizedBox.expand(child: playerBody);
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: playerBody,
    );
  }

  Widget _buildIOSPlayer() {
    return IgnorePointer(
      ignoring: true,
      child: UiKitView(
        viewType: 'turqapp.hls_player/view',
        creationParams: {
          'url': widget.url,
          'autoPlay': widget.autoPlay,
          'loop': widget.loop,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        // Feed scroll/tap gesture'ları Flutter tarafında kalsın.
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
      ),
    );
  }

  Widget _buildAndroidPlayer() {
    return IgnorePointer(
      ignoring: true,
      child: AndroidView(
        viewType: 'turqapp.hls_player/view',
        creationParams: {
          'url': widget.url,
          'autoPlay': widget.autoPlay,
          'loop': widget.loop,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        // PlatformView'in gesture yutmasını engeller; parent scroll çalışır.
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
      ),
    );
  }

  Widget _buildUnsupportedPlatform() {
    return const Center(
      child: Text(
        'HLS Player sadece iOS\'te destekleniyor',
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Controls widget
class _HLSPlayerControls extends StatefulWidget {
  final HLSController controller;

  const _HLSPlayerControls({required this.controller});

  @override
  State<_HLSPlayerControls> createState() => _HLSPlayerControlsState();
}

class _HLSPlayerControlsState extends State<_HLSPlayerControls> {
  bool _showControls = true;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        color: Colors.transparent,
        child: AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Center play/pause button
                Expanded(
                  child: Center(
                    child: StreamBuilder<PlayerState>(
                      stream: widget.controller.onStateChanged,
                      initialData: widget.controller.state,
                      builder: (context, snapshot) {
                        final state = snapshot.data ?? PlayerState.idle;

                        if (state == PlayerState.buffering) {
                          return const CircularProgressIndicator(
                            color: Colors.white,
                          );
                        }

                        return IconButton(
                          icon: Icon(
                            state == PlayerState.playing
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 64,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            widget.controller.togglePlayPause();
                          },
                        );
                      },
                    ),
                  ),
                ),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // Progress bar
                      StreamBuilder<Duration>(
                        stream: widget.controller.onPositionChanged,
                        builder: (context, positionSnapshot) {
                          return StreamBuilder<Duration>(
                            stream: widget.controller.onDurationChanged,
                            builder: (context, durationSnapshot) {
                              final position = positionSnapshot.data ?? Duration.zero;
                              final duration = durationSnapshot.data ?? Duration.zero;

                              final positionSeconds = position.inMilliseconds / 1000.0;
                              final durationSeconds = duration.inMilliseconds / 1000.0;

                              return Column(
                                children: [
                                  Slider(
                                    value: _isDragging
                                        ? positionSeconds
                                        : (durationSeconds > 0
                                            ? positionSeconds.clamp(0.0, durationSeconds)
                                            : 0.0),
                                    min: 0.0,
                                    max: durationSeconds > 0 ? durationSeconds : 1.0,
                                    activeColor: Colors.white,
                                    inactiveColor: Colors.white.withValues(alpha: 0.3),
                                    onChangeStart: (_) {
                                      setState(() {
                                        _isDragging = true;
                                      });
                                    },
                                    onChanged: (value) {
                                      // Visual feedback during drag
                                    },
                                    onChangeEnd: (value) {
                                      widget.controller.seekTo(value);
                                      setState(() {
                                        _isDragging = false;
                                      });
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(position),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(duration),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
