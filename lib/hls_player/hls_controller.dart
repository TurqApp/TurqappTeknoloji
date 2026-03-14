import 'dart:async';
import 'package:flutter/services.dart';
import 'package:turqappv2/Core/Services/video_telemetry_service.dart';

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

  // Streams
  Stream<PlayerState> get onStateChanged => _stateController.stream;
  Stream<Duration> get onPositionChanged => _positionController.stream;
  Stream<Duration> get onDurationChanged => _durationController.stream;
  Stream<bool> get onBufferingChanged => _bufferingController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<bool> get onFirstFrameChanged => _firstFrameController.stream;

  // Initialize controller with view ID
  void initialize(int viewId) {
    // Rebind güvenliği: aynı controller yeni view'a bağlanıyorsa eski stream'i kapat.
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _hasRenderedFirstFrame = false;
    _firstFrameController.add(false);
    _viewId = viewId;
    _eventChannel = EventChannel('turqapp.hls_player/events_$viewId');
    _listenToEvents();
  }

  // Load video with mp4 fallback on HLS failure
  Future<void> loadVideoWithFallback(
    String url, {
    String? fallbackUrl,
    bool autoPlay = true,
    bool loop = false,
  }) async {
    _fallbackUrl = fallbackUrl;
    _fallbackAttempted = false;
    await loadVideo(url, autoPlay: autoPlay, loop: loop);
  }

  /// Set the video document ID for telemetry tracking.
  void setTelemetryVideoId(String videoId) {
    // End previous session if still active.
    if (_telemetryVideoId != null) {
      _telemetry.endSession(_telemetryVideoId!);
    }
    _telemetryVideoId = videoId;
    _firstFrameEmitted = false;
  }

  // Load video URL
  Future<void> loadVideo(String url,
      {bool autoPlay = true, bool loop = false}) async {
    if (_viewId == null) {
      throw Exception('Controller not initialized. Call initialize() first.');
    }

    _currentUrl = url;
    _isLooping = loop;
    _updateState(PlayerState.loading);
    _firstFrameEmitted = false;
    _hasRenderedFirstFrame = false;
    _firstFrameController.add(false);
    if (_telemetryVideoId != null) {
      _telemetry.startSession(_telemetryVideoId!, url);
    }

    try {
      await _methodChannel.invokeMethod('loadVideo', {
        'viewId': _viewId,
        'url': url,
        'autoPlay': autoPlay,
        'loop': loop,
      });
    } on PlatformException catch (e) {
      _handleError('Failed to load video: ${e.message}');
    }
  }

  // Play
  Future<void> play() async {
    if (_viewId == null) return;

    try {
      await _methodChannel.invokeMethod('play', {'viewId': _viewId});
    } on PlatformException catch (e) {
      _handleError('Failed to play: ${e.message}');
    }
  }

  // Pause
  Future<void> pause() async {
    if (_viewId == null) return;

    try {
      await _methodChannel.invokeMethod('pause', {'viewId': _viewId});
    } on PlatformException catch (e) {
      _handleError('Failed to pause: ${e.message}');
    }
  }

  // Seek to position in seconds
  Future<void> seekTo(double seconds) async {
    if (_viewId == null) return;

    try {
      await _methodChannel.invokeMethod('seek', {
        'viewId': _viewId,
        'seconds': seconds,
      });
      _currentPosition = seconds;
      _positionController.add(Duration(milliseconds: (seconds * 1000).toInt()));
    } on PlatformException catch (e) {
      _handleError('Failed to seek: ${e.message}');
    }
  }

  // Set muted
  Future<void> setMuted(bool muted) async {
    if (_viewId == null) return;

    try {
      await _methodChannel.invokeMethod('setMuted', {
        'viewId': _viewId,
        'muted': muted,
      });
      _isMuted = muted;
    } on PlatformException catch (e) {
      _handleError('Failed to set muted: ${e.message}');
    }
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (_viewId == null) return;

    final clampedVolume = volume.clamp(0.0, 1.0);

    try {
      await _methodChannel.invokeMethod('setVolume', {
        'viewId': _viewId,
        'volume': clampedVolume,
      });
    } on PlatformException catch (e) {
      _handleError('Failed to set volume: ${e.message}');
    }
  }

  // Stop playback — network ve decoder serbest, controller hayatta kalır
  Future<void> stopPlayback() async {
    if (_viewId == null) return;
    try {
      await _methodChannel.invokeMethod('stopPlayback', {'viewId': _viewId});
    } on PlatformException catch (e) {
      _handleError('Failed to stop playback: ${e.message}');
    }
  }

  // Forward buffer süresini ayarla (saniye — iOS, milisaniye — Android)
  Future<void> setPreferredBufferDuration(double seconds) async {
    if (_viewId == null) return;
    try {
      await _methodChannel.invokeMethod('setPreferredBufferDuration', {
        'viewId': _viewId,
        'duration': seconds,
      });
    } on PlatformException catch (e) {
      _handleError('Failed to set buffer duration: ${e.message}');
    }
  }

  // Set loop
  Future<void> setLoop(bool loop) async {
    if (_viewId == null) return;

    try {
      await _methodChannel.invokeMethod('setLoop', {
        'viewId': _viewId,
        'loop': loop,
      });
      _isLooping = loop;
    } on PlatformException catch (e) {
      _handleError('Failed to set loop: ${e.message}');
    }
  }

  // Get current time
  Future<double> getCurrentTime() async {
    if (_viewId == null) return 0.0;

    try {
      final result =
          await _methodChannel.invokeMethod<double>('getCurrentTime', {
        'viewId': _viewId,
      });
      return result ?? 0.0;
    } on PlatformException catch (e) {
      _handleError('Failed to get current time: ${e.message}');
      return 0.0;
    }
  }

  // Get duration
  Future<double> getDuration() async {
    if (_viewId == null) return 0.0;

    try {
      final result = await _methodChannel.invokeMethod<double>('getDuration', {
        'viewId': _viewId,
      });
      return result ?? 0.0;
    } on PlatformException catch (e) {
      _handleError('Failed to get duration: ${e.message}');
      return 0.0;
    }
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_state == PlayerState.playing) {
      await pause();
    } else if (_state == PlayerState.paused || _state == PlayerState.ready) {
      await play();
    }
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

  // Private methods

  void _listenToEvents() {
    if (_eventChannel == null) return;

    _eventSubscription = _eventChannel!.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is! Map) return;

        final eventType = event['event'] as String?;

        switch (eventType) {
          case 'ready':
            final durationSeconds =
                (event['duration'] as num?)?.toDouble() ?? 0.0;
            _duration = durationSeconds;
            _durationController
                .add(Duration(milliseconds: (durationSeconds * 1000).toInt()));
            _updateState(PlayerState.ready);
            break;

          case 'play':
            _updateState(PlayerState.playing);
            break;

          case 'firstFrame':
            _markFirstFrameRendered();
            break;

          case 'pause':
            _updateState(PlayerState.paused);
            break;

          case 'buffering':
            final isBuffering = (event['isBuffering'] as bool?) ?? false;
            _bufferingController.add(isBuffering);
            if (isBuffering) {
              if (_telemetryVideoId != null) {
                _telemetry.onBufferingStart(_telemetryVideoId!);
              }
              _updateState(PlayerState.buffering);
            } else if (_state == PlayerState.buffering) {
              if (_telemetryVideoId != null) {
                _telemetry.onBufferingEnd(_telemetryVideoId!);
              }
              _updateState(PlayerState.playing);
            }
            break;

          case 'timeUpdate':
            final position = (event['position'] as num?)?.toDouble() ?? 0.0;
            final duration = (event['duration'] as num?)?.toDouble() ?? 0.0;
            _currentPosition = position;
            _duration = duration;
            _positionController
                .add(Duration(milliseconds: (position * 1000).toInt()));
            _durationController
                .add(Duration(milliseconds: (duration * 1000).toInt()));
            if (_telemetryVideoId != null) {
              _telemetry.onPositionUpdate(
                  _telemetryVideoId!, position, duration);
            }
            if (!_hasRenderedFirstFrame && position > 0) {
              _markFirstFrameRendered();
            }
            // Native tarafında 'ready/play' eventi erken kaçarsa timeUpdate ile state'i toparla.
            if (_state == PlayerState.loading || _state == PlayerState.idle) {
              _updateState(
                  position > 0 ? PlayerState.playing : PlayerState.ready);
            }
            break;

          case 'completed':
            if (_telemetryVideoId != null) {
              _telemetry.onCompleted(_telemetryVideoId!);
            }
            _updateState(PlayerState.completed);
            break;

          case 'stopped':
            _updateState(PlayerState.idle);
            break;

          case 'error':
            final message = event['message'] as String? ?? 'Unknown error';
            if (_telemetryVideoId != null) {
              _telemetry.onError(_telemetryVideoId!, message);
            }
            _handleError(message);
            break;

          case 'seekCompleted':
            final position = (event['position'] as num?)?.toDouble() ?? 0.0;
            _currentPosition = position;
            _positionController
                .add(Duration(milliseconds: (position * 1000).toInt()));
            if (_telemetryVideoId != null) {
              _telemetry.onSeek(_telemetryVideoId!);
            }
            break;
        }
      },
      onError: (dynamic error) {
        _handleError('Event stream error: $error');
      },
    );
  }

  void _updateState(PlayerState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
    }
  }

  void _markFirstFrameRendered() {
    if (_hasRenderedFirstFrame) return;
    _hasRenderedFirstFrame = true;
    _firstFrameController.add(true);
    if (!_firstFrameEmitted && _telemetryVideoId != null) {
      _firstFrameEmitted = true;
      _telemetry.onFirstFrame(_telemetryVideoId!);
    }
  }

  void _handleError(String message) {
    // Try mp4 fallback before reporting error
    if (_fallbackUrl != null && !_fallbackAttempted) {
      _fallbackAttempted = true;
      loadVideo(_fallbackUrl!);
      return;
    }

    _errorMessage = message;
    _updateState(PlayerState.error);
    _errorController.add(message);
  }
}
