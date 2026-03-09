import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

/// Uygulama genelinde tek bir aktif ses kaynağı olmasını zorlar.
class AudioFocusCoordinator extends GetxService {
  static AudioFocusCoordinator get instance {
    if (!Get.isRegistered<AudioFocusCoordinator>()) {
      Get.put(AudioFocusCoordinator());
    }
    return Get.find<AudioFocusCoordinator>();
  }

  final Set<HLSVideoAdapter> _players = <HLSVideoAdapter>{};
  final Set<AudioPlayer> _audioPlayers = <AudioPlayer>{};
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

    // HLS başlarken uygulamadaki diğer audio player kaynaklarını da sustur.
    for (final audio in _audioPlayers.toList()) {
      try {
        await audio.pause();
      } catch (_) {}
    }

    final others = _players.where((p) => !identical(p, player)).toList();
    for (final p in others) {
      try {
        await p.pause();
        await p.setVolume(0.0);
      } catch (_) {}
    }

    // iOS'ta hızlı page geçişlerinde eski player kısa süre tekrar ses verebilir.
    // Kısa bir doğrulama turu ile sadece aktif player'ın sesini açık bırak.
    Future.delayed(const Duration(milliseconds: 120), () async {
      if (epoch != _focusEpoch) return;
      final active = _activePlayer;
      if (active == null) return;
      for (final p in _players.toList()) {
        if (identical(p, active)) continue;
        try {
          await p.pause();
          await p.setVolume(0.0);
        } catch (_) {}
      }
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

  Future<void> pauseAllAudioPlayers() async {
    _focusEpoch++;
    _activePlayer = null;

    for (final player in _players.toList()) {
      try {
        await player.pause();
        await player.setVolume(0.0);
      } catch (_) {}
    }

    for (final player in _audioPlayers.toList()) {
      try {
        await player.pause();
      } catch (_) {}
    }
  }
}
