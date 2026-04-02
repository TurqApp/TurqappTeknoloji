import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:turqappv2/hls_player/hls_controller.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

/// Abstract interface for video playback control.
/// Bridges both HLSController (native) and VideoPlayerController (legacy).
abstract class PlaybackHandle {
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
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
  Future<void> stop() => controller.stopPlayback();

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

/// HLS adapter handle.
/// Audio focus coordinator'ın devreye girmesi için adapter API'sini kullanır.
class HLSAdapterPlaybackHandle implements PlaybackHandle {
  final HLSVideoAdapter adapter;

  HLSAdapterPlaybackHandle(this.adapter);

  @override
  Future<void> play() => adapter.play();

  @override
  Future<void> pause() => adapter.pause();

  @override
  Future<void> stop() => adapter.silenceAndStopPlayback();

  @override
  bool get isPlaying => adapter.value.isPlaying;

  @override
  bool get isInitialized => adapter.value.isInitialized;

  @override
  Duration get position => adapter.value.position;

  @override
  Duration get duration => adapter.value.duration;

  @override
  Future<void> seekTo(Duration position) => adapter.seekTo(position);

  @override
  Future<void> setVolume(double volume) => adapter.setVolume(volume);

  @override
  Future<void> dispose() async {}
}

/// Legacy video_player handle (for backward compatibility).
class LegacyPlaybackHandle implements PlaybackHandle {
  final VideoPlayerController controller;
  bool _isDisposed = false;

  LegacyPlaybackHandle(this.controller);

  @override
  Future<void> play() async {
    if (_isDisposed) return;
    await controller.play();
  }

  @override
  Future<void> pause() async {
    if (_isDisposed) return;
    await controller.pause();
  }

  @override
  Future<void> stop() async {
    if (_isDisposed) return;
    await controller.pause();
    await controller.dispose();
    _isDisposed = true;
  }

  @override
  bool get isPlaying => !_isDisposed && controller.value.isPlaying;

  @override
  bool get isInitialized => !_isDisposed && controller.value.isInitialized;

  @override
  Duration get position =>
      _isDisposed ? Duration.zero : controller.value.position;

  @override
  Duration get duration =>
      _isDisposed ? Duration.zero : controller.value.duration;

  @override
  Future<void> seekTo(Duration position) async {
    if (_isDisposed) return;
    await controller.seekTo(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_isDisposed) return;
    await controller.setVolume(volume);
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    await controller.dispose();
    _isDisposed = true;
  }
}
