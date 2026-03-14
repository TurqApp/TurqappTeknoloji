import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'hls_controller.dart';
import 'hls_player.dart';
import '../Core/Services/SegmentCache/hls_proxy_server.dart';
import '../Core/Services/audio_focus_coordinator.dart';

/// VideoPlayerController-benzeri API sunan HLSController adapter.
class HLSVideoValue {
  final bool isInitialized;
  final bool isPlaying;
  final bool isBuffering;
  final bool hasRenderedFirstFrame;
  final Duration position;
  final Duration duration;
  final Size size;
  final double aspectRatio;
  final List<DurationRange> buffered;

  const HLSVideoValue({
    this.isInitialized = false,
    this.isPlaying = false,
    this.isBuffering = false,
    this.hasRenderedFirstFrame = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.size = const Size(1920, 1080),
    this.aspectRatio = 16 / 9,
    this.buffered = const [],
  });
}

class DurationRange {
  final Duration start;
  final Duration end;
  DurationRange(this.start, this.end);
}

/// HLSController'ı sarmalayan adapter.
/// Stream'lere constructor'da abone olur.
/// View hazır olmadan gelen play/pause/seek/volume komutlarını kuyruklar
/// ve view ready olduğunda otomatik çalıştırır.
class HLSVideoAdapter extends ChangeNotifier {
  final HLSController _hls = HLSController();
  final String _originalUrl;
  String _effectiveUrl;
  final bool autoPlay;
  final bool loop;
  final bool? _coordinateAudioFocus;
  bool get coordinateAudioFocus => _coordinateAudioFocus ?? true;

  /// CDN URL'yi proxy URL'ye çevir. Proxy başlamadıysa orijinal URL döner.
  static String _resolveToProxy(String originalUrl) {
    if (!originalUrl.contains('cdn.turqapp.com')) return originalUrl;
    try {
      final proxy = Get.find<HLSProxyServer>();
      return proxy.resolveUrl(originalUrl);
    } catch (_) {
      return originalUrl;
    }
  }

  HLSVideoValue _value = const HLSVideoValue();
  HLSVideoValue get value => _value;

  StreamSubscription? _stateSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _firstFrameSub;

  bool _viewReady = false;
  bool _disposed = false;
  bool _isStopped = false;
  bool get isDisposed => _disposed;

  /// Network/decoder durdurulmuş mu? (stopPlayback çağrıldı)
  bool get isStopped => _isStopped;

  // Pending command queue
  bool _wantPlay = false;
  bool _wantPause = false;
  double _pendingVolume = 1.0;
  bool _hasPendingVolume = false;
  Duration? _pendingSeek;

  HLSController get hlsController => _hls;

  HLSVideoAdapter({
    required String url,
    this.autoPlay = false,
    this.loop = false,
    bool coordinateAudioFocus = true,
  })  : _originalUrl = url,
        _coordinateAudioFocus = coordinateAudioFocus,
        _effectiveUrl = _resolveToProxy(url) {
    if (coordinateAudioFocus) {
      AudioFocusCoordinator.instance.register(this);
    }
    // Stream'lere hemen abone ol.
    // HLSPlayer widget mount olup native view oluşturduğunda
    // HLSController.initialize(viewId) çağrılır ve event'ler akmaya başlar.
    _subscribeToStreams();
  }

  String get url => _effectiveUrl;

  void _refreshProxyUrlIfNeeded() {
    final next = _resolveToProxy(_originalUrl);
    if (next != _effectiveUrl) {
      _effectiveUrl = next;
      debugPrint('[HLSAdapter] Proxy URL aktif: $_effectiveUrl');
    }
  }

  /// Warm pool'dan geri gelen adapter yeni native view'a bağlanmadan önce
  /// stale ready state'ini bırakmalı; aksi halde volume/seek/play eski view'a gider.
  void prepareForReuse() {
    if (_disposed) return;
    _viewReady = false;
    _isStopped = false;
    _value = HLSVideoValue(
      isInitialized: false,
      isPlaying: false,
      isBuffering: false,
      hasRenderedFirstFrame: false,
      position: _value.position,
      duration: _value.duration,
      size: _value.size,
      aspectRatio: _value.aspectRatio,
      buffered: _value.buffered,
    );
    notifyListeners();
  }

  void _subscribeToStreams() {
    _stateSub = _hls.onStateChanged.listen((state) {
      if (_disposed) return;

      final wasReady = _viewReady;
      _viewReady = state != PlayerState.idle && state != PlayerState.loading;

      _value = HLSVideoValue(
        isInitialized: _viewReady,
        isPlaying: state == PlayerState.playing,
        isBuffering: state == PlayerState.buffering,
        hasRenderedFirstFrame: _value.hasRenderedFirstFrame,
        position: _value.position,
        duration: _value.duration,
        size: _value.size,
        aspectRatio: _value.aspectRatio,
        buffered: _value.buffered,
      );
      notifyListeners();

      // İlk kez ready olduğunda bekleyen komutları çalıştır
      if (_viewReady && !wasReady) {
        _executePendingCommands();
      }
    });

    _posSub = _hls.onPositionChanged.listen((pos) {
      if (_disposed) return;
      _value = HLSVideoValue(
        isInitialized: _value.isInitialized,
        isPlaying: _value.isPlaying,
        isBuffering: _value.isBuffering,
        hasRenderedFirstFrame: _value.hasRenderedFirstFrame,
        position: pos,
        duration: _value.duration,
        size: _value.size,
        aspectRatio: _value.aspectRatio,
        buffered: _value.buffered,
      );
      notifyListeners();
    });

    _durSub = _hls.onDurationChanged.listen((dur) {
      if (_disposed) return;
      _value = HLSVideoValue(
        isInitialized: _value.isInitialized,
        isPlaying: _value.isPlaying,
        isBuffering: _value.isBuffering,
        hasRenderedFirstFrame: _value.hasRenderedFirstFrame,
        position: _value.position,
        duration: dur,
        size: _value.size,
        aspectRatio: _value.aspectRatio,
        buffered: _value.buffered,
      );
      notifyListeners();
    });

    _firstFrameSub = _hls.onFirstFrameChanged.listen((hasRenderedFirstFrame) {
      if (_disposed) return;
      _value = HLSVideoValue(
        isInitialized: _value.isInitialized,
        isPlaying: _value.isPlaying,
        isBuffering: _value.isBuffering,
        hasRenderedFirstFrame: hasRenderedFirstFrame,
        position: _value.position,
        duration: _value.duration,
        size: _value.size,
        aspectRatio: _value.aspectRatio,
        buffered: _value.buffered,
      );
      notifyListeners();
    });
  }

  void _executePendingCommands() {
    if (_hasPendingVolume) {
      _hls.setVolume(_pendingVolume);
      _hasPendingVolume = false;
    }
    if (_pendingSeek != null) {
      _hls.seekTo(_pendingSeek!.inMilliseconds / 1000.0);
      _pendingSeek = null;
    }
    if (_wantPlay) {
      _hls.play();
      _wantPlay = false;
      _wantPause = false;
    } else if (_wantPause) {
      _hls.pause();
      _wantPause = false;
    }
  }

  Future<void> play() {
    if (_disposed) return Future.value();
    return _playWithAudioFocus();
  }

  Future<void> _playWithAudioFocus() async {
    if (_disposed) return;
    if (coordinateAudioFocus) {
      try {
        await AudioFocusCoordinator.instance.requestPlay(this);
      } catch (_) {}
    }
    _refreshProxyUrlIfNeeded();
    // Stopped ise otomatik reload + play
    if (_isStopped) {
      _isStopped = false;
      _wantPlay = true;
      _wantPause = false;
      if (_viewReady) {
        await _hls.loadVideo(url, autoPlay: true, loop: loop);
        return;
      }
      return;
    }
    if (_viewReady) {
      _wantPlay = false;
      _wantPause = false;
      await _hls.play();
      return;
    }
    _wantPlay = true;
    _wantPause = false;
  }

  Future<void> pause() {
    if (_disposed) return Future.value();
    if (coordinateAudioFocus) {
      try {
        AudioFocusCoordinator.instance.requestPause(this);
      } catch (_) {}
    }
    if (_viewReady) {
      _wantPlay = false;
      _wantPause = false;
      return _hls.pause();
    }
    _wantPause = true;
    _wantPlay = false;
    return Future.value();
  }

  Future<void> setVolume(double v) {
    if (_disposed) return Future.value();
    if (_viewReady) return _hls.setVolume(v);
    _pendingVolume = v;
    _hasPendingVolume = true;
    return Future.value();
  }

  Future<void> setLooping(bool v) {
    if (_disposed) return Future.value();
    if (_viewReady) return _hls.setLoop(v);
    return Future.value();
  }

  Future<void> seekTo(Duration pos) {
    if (_disposed) return Future.value();
    if (_viewReady) return _hls.seekTo(pos.inMilliseconds / 1000.0);
    _pendingSeek = pos;
    return Future.value();
  }

  /// Network/decoder durdur, adapter hayatta kalsın.
  /// Tekrar play() çağrılırsa otomatik reload olur.
  Future<void> stopPlayback() {
    if (_disposed) return Future.value();
    _isStopped = true;
    _wantPlay = false;
    _wantPause = false;
    if (_viewReady) {
      return _hls.stopPlayback();
    }
    return Future.value();
  }

  /// stopPlayback sonrası videoyu tekrar yükle.
  Future<void> reloadVideo() async {
    if (_disposed) return;
    _refreshProxyUrlIfNeeded();
    if (!_isStopped) return;
    _isStopped = false;
    if (_viewReady) {
      await _hls.loadVideo(url, autoPlay: false, loop: loop);
    }
  }

  /// Forward buffer süresini ayarla (saniye).
  Future<void> setPreferredBufferDuration(double seconds) {
    if (_disposed) return Future.value();
    if (_viewReady) return _hls.setPreferredBufferDuration(seconds);
    return Future.value();
  }

  /// VideoPlayer widget yerine kullanılacak widget.
  /// HLSPlayer, mount edildiğinde native view oluşturur ve
  /// HLSController.initialize(viewId) çağırır → event'ler akmaya başlar.
  /// Pending seek/play kuyruğunu hazırla (fullscreen geçişi gibi view yenilenecek durumlar için).
  /// Yeni native view ready olduğunda bu komutlar otomatik çalışır.
  void queueSeekAndPlay(Duration position) {
    _wantPlay = true;
    _wantPause = false;
    if (position > Duration.zero) {
      _pendingSeek = position;
    }
  }

  Widget buildPlayer({
    Key? key,
    double aspectRatio = 16 / 9,
    bool useAspectRatio = true,
    bool? overrideAutoPlay,
  }) {
    if (_disposed) return const SizedBox.shrink();
    _refreshProxyUrlIfNeeded();
    return HLSPlayer(
      key: key,
      url: url,
      controller: _hls,
      autoPlay: overrideAutoPlay ?? autoPlay,
      loop: loop,
      showControls: false,
      aspectRatio: aspectRatio,
      useAspectRatio: useAspectRatio,
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (coordinateAudioFocus) {
      try {
        AudioFocusCoordinator.instance.unregister(this);
      } catch (_) {}
    }
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _firstFrameSub?.cancel();
    _hls.dispose();
    super.dispose();
  }
}
