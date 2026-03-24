import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/video_telemetry_service.dart';

part 'hls_controller_diagnostics_part.dart';
part 'hls_controller_events_part.dart';
part 'hls_controller_playback_part.dart';

const bool _suppressHlsSmokeLogs =
    bool.fromEnvironment('RUN_INTEGRATION_SMOKE', defaultValue: false);

enum PlayerState {
  idle,
  loading,
  ready,
  playing,
  paused,
  buffering,
  completed,
  error,
}

class HLSController {
  static const MethodChannel _methodChannel =
      MethodChannel('turqapp.hls_player/method');

  static Future<Map<String, dynamic>> getActiveSmokeSnapshot() async {
    try {
      final result = await _methodChannel.invokeMethod<dynamic>(
        'getActiveSmokeSnapshot',
      );
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return const <String, dynamic>{};
    } on PlatformException {
      return const <String, dynamic>{};
    }
  }

  int? _viewId;
  EventChannel? _eventChannel;
  StreamSubscription? _eventSubscription;

  // Player state
  PlayerState _state = PlayerState.idle;
  String? _currentUrl;
  double _currentPosition = 0.0;
  double _duration = 0.0;
  bool _isMuted = false;
  bool _isLooping = false;
  String? _errorMessage;
  bool _hasRenderedFirstFrame = false;
  double? _pendingReattachSeekSeconds;
  bool _pendingReattachShouldPlay = false;
  int _rendererStallCount = 0;
  int _surfaceRebindCount = 0;

  // Fallback support
  String? _fallbackUrl;
  bool _fallbackAttempted = false;

  // Telemetry
  final _telemetry = VideoTelemetryService.instance;
  String? _telemetryVideoId;
  bool _firstFrameEmitted = false;

  // Stream controllers
  final _stateController = StreamController<PlayerState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _bufferingController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _firstFrameController = StreamController<bool>.broadcast();

  // Getters
  PlayerState get state => _state;
  String? get currentUrl => _currentUrl;
  double get currentPosition => _currentPosition;
  double get duration => _duration;
  bool get isMuted => _isMuted;
  bool get isLooping => _isLooping;
  String? get errorMessage => _errorMessage;
  bool get isPlaying => _state == PlayerState.playing;
  bool get isPaused => _state == PlayerState.paused;
  bool get isReady => _state == PlayerState.ready;
  bool get hasRenderedFirstFrame => _hasRenderedFirstFrame;
  int get rendererStallCount => _rendererStallCount;
  int get surfaceRebindCount => _surfaceRebindCount;

  bool get _isAtPlaybackEnd {
    if (!_duration.isFinite || _duration <= 0) return false;
    if (!_currentPosition.isFinite) return false;
    final remaining = _duration - _currentPosition;
    return remaining <= 0.35;
  }

  void cancelPendingResume() {
    _pendingReattachSeekSeconds = null;
    _pendingReattachShouldPlay = false;
  }

  // Streams
  Stream<PlayerState> get onStateChanged => _stateController.stream;
  Stream<Duration> get onPositionChanged => _positionController.stream;
  Stream<Duration> get onDurationChanged => _durationController.stream;
  Stream<bool> get onBufferingChanged => _bufferingController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<bool> get onFirstFrameChanged => _firstFrameController.stream;

  // Initialize controller with view ID
  void initialize(int viewId) {
    final previousViewId = _viewId;
    final hadBoundView = previousViewId != null;
    if (hadBoundView) {
      final previousPosition =
          _currentPosition.isFinite ? _currentPosition : 0.0;
      final shouldRestorePosition = previousPosition > 0.05;
      final shouldResumePlay =
          _state == PlayerState.playing || _state == PlayerState.buffering;
      if (shouldRestorePosition || shouldResumePlay) {
        _pendingReattachSeekSeconds = previousPosition;
        _pendingReattachShouldPlay = shouldResumePlay;
      }
    }

    if (previousViewId != null && previousViewId != viewId) {
      unawaited(_silencePreviousView(previousViewId));
    }

    // Rebind güvenliği: aynı controller yeni view'a bağlanıyorsa eski stream'i kapat.
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _hasRenderedFirstFrame = false;
    _firstFrameController.add(false);
    _rendererStallCount = 0;
    _surfaceRebindCount = 0;
    _viewId = viewId;
    _eventChannel = EventChannel('turqapp.hls_player/events_$viewId');
    _listenToEvents();
  }

  Future<void> _silencePreviousView(int previousViewId) async {
    try {
      await _methodChannel.invokeMethod('setVolume', {
        'viewId': previousViewId,
        'volume': 0.0,
      });
    } catch (_) {}

    try {
      await _methodChannel.invokeMethod('pause', {
        'viewId': previousViewId,
      });
    } catch (_) {}

    try {
      await _methodChannel.invokeMethod('stopPlayback', {
        'viewId': previousViewId,
      });
    } catch (_) {}
  }

  Future<void> loadVideoWithFallback(
    String url, {
    String? fallbackUrl,
    bool autoPlay = true,
    bool loop = false,
  }) {
    return HLSControllerPlaybackPart(this).loadVideoWithFallback(
      url,
      fallbackUrl: fallbackUrl,
      autoPlay: autoPlay,
      loop: loop,
    );
  }

  void setTelemetryVideoId(String videoId) {
    HLSControllerPlaybackPart(this).setTelemetryVideoId(videoId);
  }

  Future<void> loadVideo(
    String url, {
    bool autoPlay = true,
    bool loop = false,
  }) {
    return HLSControllerPlaybackPart(
      this,
    ).loadVideo(url, autoPlay: autoPlay, loop: loop);
  }

  Future<void> play() => HLSControllerPlaybackPart(this).play();

  Future<void> pause() => HLSControllerPlaybackPart(this).pause();

  Future<void> seekTo(double seconds) {
    return HLSControllerPlaybackPart(this).seekTo(seconds);
  }

  Future<void> setMuted(bool muted) {
    return HLSControllerPlaybackPart(this).setMuted(muted);
  }

  Future<void> setVolume(double volume) {
    return HLSControllerPlaybackPart(this).setVolume(volume);
  }

  Future<void> stopPlayback() => HLSControllerPlaybackPart(this).stopPlayback();

  Future<void> setPreferredBufferDuration(double seconds) {
    return HLSControllerPlaybackPart(this).setPreferredBufferDuration(seconds);
  }

  Future<void> setLoop(bool loop) =>
      HLSControllerPlaybackPart(this).setLoop(loop);

  Future<double> getCurrentTime() {
    return HLSControllerDiagnosticsPart(this).getCurrentTime();
  }

  Future<double> getDuration() {
    return HLSControllerDiagnosticsPart(this).getDuration();
  }

  Future<bool> isMutedNative() {
    return HLSControllerDiagnosticsPart(this).isMutedNative();
  }

  Future<bool> isPlayingNative() {
    return HLSControllerDiagnosticsPart(this).isPlayingNative();
  }

  Future<bool> isBufferingNative() {
    return HLSControllerDiagnosticsPart(this).isBufferingNative();
  }

  Future<Map<String, dynamic>> getPlaybackDiagnostics() {
    return HLSControllerDiagnosticsPart(this).getPlaybackDiagnostics();
  }

  Future<Map<String, dynamic>> getProcessDiagnostics() {
    return HLSControllerDiagnosticsPart(this).getProcessDiagnostics();
  }

  Future<void> togglePlayPause() {
    return HLSControllerPlaybackPart(this).togglePlayPause();
  }

  // Dispose
  Future<void> dispose() async {
    if (_telemetryVideoId != null) {
      _telemetry.endSession(_telemetryVideoId!);
      _telemetryVideoId = null;
    }

    if (_viewId != null) {
      try {
        await _methodChannel.invokeMethod('dispose', {'viewId': _viewId});
      } catch (e) {
        // Ignore errors during dispose
      }
    }

    await _eventSubscription?.cancel();
    _eventSubscription = null;

    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
    await _bufferingController.close();
    await _errorController.close();
    await _firstFrameController.close();

    _viewId = null;
    _eventChannel = null;
  }
}
