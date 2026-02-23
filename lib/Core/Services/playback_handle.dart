import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:turqappv2/hls_player/hls_controller.dart';

/// Abstract interface for video playback control.
/// Bridges both HLSController (native) and VideoPlayerController (legacy).
abstract class PlaybackHandle {
  Future<void> play();
  Future<void> pause();
  bool get isPlaying;
  bool get isInitialized;
  Duration get position;
  Duration get duration;
  Future<void> seekTo(Duration position);
  Future<void> setVolume(double volume);
  Future<void> dispose();
}

/// Native HLS player handle (AVPlayer on iOS, ExoPlayer on Android).
class HLSPlaybackHandle implements PlaybackHandle {
  final HLSController controller;

  HLSPlaybackHandle(this.controller);

  @override
  Future<void> play() => controller.play();

  @override
  Future<void> pause() => controller.pause();

  @override
  bool get isPlaying => controller.isPlaying;

  @override
  bool get isInitialized =>
      controller.state != PlayerState.idle &&
      controller.state != PlayerState.loading;

  @override
  Duration get position =>
      Duration(milliseconds: (controller.currentPosition * 1000).toInt());

  @override
  Duration get duration =>
      Duration(milliseconds: (controller.duration * 1000).toInt());

  @override
  Future<void> seekTo(Duration position) =>
      controller.seekTo(position.inMilliseconds / 1000.0);

  @override
  Future<void> setVolume(double volume) => controller.setVolume(volume);

  @override
  Future<void> dispose() => controller.dispose();
}

/// Legacy video_player handle (for backward compatibility).
class LegacyPlaybackHandle implements PlaybackHandle {
  final VideoPlayerController controller;

  LegacyPlaybackHandle(this.controller);

  @override
  Future<void> play() => controller.play();

  @override
  Future<void> pause() => controller.pause();

  @override
  bool get isPlaying => controller.value.isPlaying;

  @override
  bool get isInitialized => controller.value.isInitialized;

  @override
  Duration get position => controller.value.position;

  @override
  Duration get duration => controller.value.duration;

  @override
  Future<void> seekTo(Duration position) => controller.seekTo(position);

  @override
  Future<void> setVolume(double volume) => controller.setVolume(volume);

  @override
  Future<void> dispose() => controller.dispose();
}
