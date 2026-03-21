import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

/// Uygulama genelinde tek bir aktif ses kaynağı olmasını zorlar.
class AudioFocusCoordinator extends GetxService {
  static AudioFocusCoordinator _ensureService() {
    if (Get.isRegistered<AudioFocusCoordinator>()) {
      return Get.find<AudioFocusCoordinator>();
    }
    return Get.put(AudioFocusCoordinator());
  }

  static AudioFocusCoordinator get instance {
    return _ensureService();
  }

  final Set<HLSVideoAdapter> _players = <HLSVideoAdapter>{};
  final Set<AudioPlayer> _audioPlayers = <AudioPlayer>{};
  final Set<VideoPlayerController> _previewPlayers = <VideoPlayerController>{};
  HLSVideoAdapter? _activePlayer;
  int _focusEpoch = 0;

  void register(HLSVideoAdapter player) {
    _players.add(player);
  }

  void unregister(HLSVideoAdapter player) {
    _players.remove(player);
    if (identical(_activePlayer, player)) {
      _activePlayer = null;
    }
  }

  Future<void> requestPlay(HLSVideoAdapter player) async {
    final int epoch = ++_focusEpoch;
    _activePlayer = player;

    await _pauseAudioPlayersExcept();
    await _pausePreviewPlayersExcept();
    await _pauseHlsPlayersExcept(player);

    // iOS'ta hızlı page geçişlerinde eski player kısa süre tekrar ses verebilir.
    // Kısa bir doğrulama turu ile sadece aktif player'ın sesini açık bırak.
    Future.delayed(const Duration(milliseconds: 120), () async {
      if (epoch != _focusEpoch) return;
      final active = _activePlayer;
      if (active == null) return;
      await _pauseHlsPlayersExcept(active);
      await _pausePreviewPlayersExcept();
      await _pauseAudioPlayersExcept();
    });
  }

  void requestPause(HLSVideoAdapter player) {
    if (identical(_activePlayer, player)) {
      _activePlayer = null;
    }
  }

  void registerAudioPlayer(AudioPlayer player) {
    _audioPlayers.add(player);
  }

  void unregisterAudioPlayer(AudioPlayer player) {
    _audioPlayers.remove(player);
  }

  void registerPreviewPlayer(VideoPlayerController controller) {
    _previewPlayers.add(controller);
  }

  void unregisterPreviewPlayer(VideoPlayerController controller) {
    _previewPlayers.remove(controller);
  }

  Future<void> requestAudioPlayerPlay(AudioPlayer player) async {
    _focusEpoch++;
    _activePlayer = null;
    await _pauseHlsPlayersExcept();
    await _pausePreviewPlayersExcept();
    await _pauseAudioPlayersExcept(player);
  }

  Future<void> requestPreviewPlay(
    VideoPlayerController controller, {
    bool exclusiveAudio = true,
  }) async {
    _focusEpoch++;
    if (exclusiveAudio) {
      _activePlayer = null;
      await _pauseHlsPlayersExcept();
      await _pauseAudioPlayersExcept();
    }
    await _pausePreviewPlayersExcept(controller);
  }

  Future<void> pauseAllAudioPlayers() async {
    _focusEpoch++;
    _activePlayer = null;

    await _pauseHlsPlayersExcept();
    await _pausePreviewPlayersExcept();
    await _pauseAudioPlayersExcept();
  }

  Future<void> _pauseHlsPlayersExcept([HLSVideoAdapter? except]) async {
    final others = _players.where((p) => !identical(p, except)).toList();
    for (final p in others) {
      try {
        await p.forceSilence();
      } catch (_) {}
    }
  }

  Future<void> _pauseAudioPlayersExcept([AudioPlayer? except]) async {
    for (final player in _audioPlayers.toList()) {
      if (identical(player, except)) continue;
      try {
        await player.pause();
      } catch (_) {}
    }
  }

  Future<void> _pausePreviewPlayersExcept([
    VideoPlayerController? except,
  ]) async {
    for (final controller in _previewPlayers.toList()) {
      if (identical(controller, except)) continue;
      try {
        await controller.pause();
      } catch (_) {}
    }
  }
}
