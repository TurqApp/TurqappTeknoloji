import 'dart:async';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'hls_controller.dart';
import 'hls_player.dart';
import '../Core/Services/SegmentCache/hls_proxy_server.dart';
import '../Core/Services/audio_focus_coordinator.dart';

part 'hls_video_adapter_playback_part.dart';
part 'hls_video_adapter_state_part.dart';

/// VideoPlayerController-benzeri API sunan HLSController adapter.
class HLSVideoValue {
  final bool isInitialized;
  final bool isPlaying;
  final bool isBuffering;
  final bool isCompleted;
  final bool hasRenderedFirstFrame;
  final bool awaitingFreshFrameAfterReattach;
  final Duration position;
  final Duration duration;
  final Size size;
  final double aspectRatio;
  final List<DurationRange> buffered;

  const HLSVideoValue({
    this.isInitialized = false,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isCompleted = false,
    this.hasRenderedFirstFrame = false,
    this.awaitingFreshFrameAfterReattach = false,
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
  final bool _useLocalProxy;
  final bool autoPlay;
  final bool loop;
  final bool? _coordinateAudioFocus;
  bool get coordinateAudioFocus => _coordinateAudioFocus ?? true;

  static String _resolvePlaybackUrl(
    String originalUrl, {
    required bool useLocalProxy,
  }) {
    if (!useLocalProxy) return originalUrl;
    if (!originalUrl.contains('cdn.turqapp.com')) return originalUrl;
    final proxy = maybeFindHlsProxyServer();
    if (proxy == null) return originalUrl;
    return proxy.resolveUrl(originalUrl);
  }

  HLSVideoValue _value = const HLSVideoValue();
  HLSVideoValue get value => _value;

  void _notifyAdapterListeners() {
    notifyListeners();
  }

  StreamSubscription? _stateSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _firstFrameSub;

  bool _viewReady = false;
  bool _disposed = false;
  bool _isStopped = false;
  bool _preferWarmPoolPause = false;
  bool get isDisposed => _disposed;

  /// Network/decoder durdurulmuş mu? (stopPlayback çağrıldı)
  bool get isStopped => _isStopped;
  bool get preferWarmPoolPause => _preferWarmPoolPause;

  // Pending command queue
  bool _wantPlay = false;
  bool _wantPause = false;
  bool _pendingReloadOnReady = false;
  double _pendingVolume = 1.0;
  bool _hasPendingVolume = false;
  Duration? _pendingSeek;
  double? _pendingPreferredBufferDurationSeconds;

  HLSController get hlsController => _hls;
  int get rendererStallCount => _hls.rendererStallCount;
  int get surfaceRebindCount => _hls.surfaceRebindCount;
  String get originalUrl => _originalUrl;
  bool get usesLocalProxy => _useLocalProxy;
  Future<bool> isPlayingNative() => _hls.isPlayingNative();
  Future<bool> isBufferingNative() => _hls.isBufferingNative();
  Future<Map<String, dynamic>> getPlaybackDiagnostics() =>
      _hls.getPlaybackDiagnostics();
  Future<Map<String, dynamic>> getProcessDiagnostics() =>
      _hls.getProcessDiagnostics();

  Future<void> recoverFrozenPlayback() => _performRecoverFrozenPlayback();

  HLSVideoAdapter({
    required String url,
    this.autoPlay = false,
    this.loop = false,
    bool useLocalProxy = true,
    bool coordinateAudioFocus = true,
  })  : _originalUrl = url,
        _useLocalProxy = useLocalProxy,
        _coordinateAudioFocus = coordinateAudioFocus,
        _effectiveUrl = _resolvePlaybackUrl(
          url,
          useLocalProxy: useLocalProxy,
        ) {
    if (coordinateAudioFocus) {
      AudioFocusCoordinator.instance.register(this);
    }
    // Stream'lere hemen abone ol.
    // HLSPlayer widget mount olup native view oluşturduğunda
    // HLSController.initialize(viewId) çağrılır ve event'ler akmaya başlar.
    _subscribeToStreams();
  }

  String get url => _effectiveUrl;

  void _refreshProxyUrlIfNeeded() => _performRefreshProxyUrlIfNeeded();

  /// Warm pool'dan geri gelen adapter yeni native view'a bağlanmadan önce
  /// stale ready state'ini bırakmalı; aksi halde volume/seek/play eski view'a gider.
  void prepareForReuse() => _performPrepareForReuse();

  void _subscribeToStreams() => _performSubscribeToStreams();

  void _executePendingCommands() => _performExecutePendingCommands();

  Future<void> play() => _performPlay();

  Future<void> _playWithAudioFocus() => _performPlayWithAudioFocus();

  Future<void> pause() => _performPause();

  Future<void> forceSilence() => _performForceSilence();

  Future<void> setVolume(double v) => _performSetVolume(v);

  Future<void> setLooping(bool v) => _performSetLooping(v);

  Future<bool> isMutedNative() => _performIsMutedNative();

  Future<void> seekTo(Duration pos) => _performSeekTo(pos);

  /// Network/decoder durdur, adapter hayatta kalsın.
  /// Tekrar play() çağrılırsa otomatik reload olur.
  Future<void> stopPlayback() => _performStopPlayback();

  /// Audio çıkışını önce susturup ardından native playback'i durdur.
  /// Android warm pool ve dormant handle cleanup için tek giriş noktasıdır.
  Future<void> silenceAndStopPlayback() => _performSilenceAndStopPlayback();

  /// stopPlayback sonrası videoyu tekrar yükle.
  Future<void> reloadVideo() => _performReloadVideo();

  /// Forward buffer süresini ayarla (saniye).
  Future<void> setPreferredBufferDuration(double seconds) =>
      _performSetPreferredBufferDuration(seconds);

  /// VideoPlayer widget yerine kullanılacak widget.
  /// HLSPlayer, mount edildiğinde native view oluşturur ve
  /// HLSController.initialize(viewId) çağırır → event'ler akmaya başlar.
  /// Pending seek/play kuyruğunu hazırla (fullscreen geçişi gibi view yenilenecek durumlar için).
  /// Yeni native view ready olduğunda bu komutlar otomatik çalışır.
  void queueSeekAndPlay(Duration position) =>
      _performQueueSeekAndPlay(position);

  Widget buildPlayer({
    Key? key,
    double aspectRatio = 16 / 9,
    bool useAspectRatio = true,
    bool? overrideAutoPlay,
    bool forceFullscreenOnAndroid = false,
    bool isPrimaryFeedSurface = false,
    bool preferResumePoster = false,
    bool suppressLoadingOverlay = false,
  }) =>
      _performBuildPlayer(
        key: key,
        aspectRatio: aspectRatio,
        useAspectRatio: useAspectRatio,
        overrideAutoPlay: overrideAutoPlay,
        forceFullscreenOnAndroid: forceFullscreenOnAndroid,
        isPrimaryFeedSurface: isPrimaryFeedSurface,
        preferResumePoster: preferResumePoster,
        suppressLoadingOverlay: suppressLoadingOverlay,
      );

  void updateWarmPoolPausePreference(bool value) {
    _preferWarmPoolPause = value;
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
