part of 'audio_focus_coordinator.dart';

AudioFocusCoordinator? _maybeFindAudioFocusCoordinator() {
  final isRegistered = Get.isRegistered<AudioFocusCoordinator>();
  if (!isRegistered) return null;
  return Get.find<AudioFocusCoordinator>();
}

AudioFocusCoordinator _ensureAudioFocusCoordinator() {
  final existing = _maybeFindAudioFocusCoordinator();
  if (existing != null) return existing;
  return Get.put(AudioFocusCoordinator());
}

class _AudioFocusCoordinatorRuntimePart {
  final AudioFocusCoordinator controller;

  const _AudioFocusCoordinatorRuntimePart(this.controller);

  void register(HLSVideoAdapter player) {
    controller._players.add(player);
  }

  void unregister(HLSVideoAdapter player) {
    controller._players.remove(player);
    if (identical(controller._activePlayer, player)) {
      controller._activePlayer = null;
    }
  }

  Future<void> requestPlay(HLSVideoAdapter player) async {
    final int epoch = ++controller._focusEpoch;
    controller._activePlayer = player;

    await _pauseAudioPlayersExcept();
    await _pausePreviewPlayersExcept();
    await _pauseHlsPlayersExcept(player);

    Future.delayed(const Duration(milliseconds: 120), () async {
      if (epoch != controller._focusEpoch) return;
      final active = controller._activePlayer;
      if (active == null) return;
      await _pauseHlsPlayersExcept(active);
      await _pausePreviewPlayersExcept();
      await _pauseAudioPlayersExcept();
    });
  }

  void requestPause(HLSVideoAdapter player) {
    if (identical(controller._activePlayer, player)) {
      controller._activePlayer = null;
    }
  }

  void registerAudioPlayer(AudioPlayer player) {
    controller._audioPlayers.add(player);
  }

  void unregisterAudioPlayer(AudioPlayer player) {
    controller._audioPlayers.remove(player);
  }

  void registerPreviewPlayer(VideoPlayerController previewController) {
    controller._previewPlayers.add(previewController);
  }

  void unregisterPreviewPlayer(VideoPlayerController previewController) {
    controller._previewPlayers.remove(previewController);
  }

  Future<void> requestAudioPlayerPlay(AudioPlayer player) async {
    controller._focusEpoch++;
    controller._activePlayer = null;
    await _pauseHlsPlayersExcept();
    await _pausePreviewPlayersExcept();
    await _pauseAudioPlayersExcept(player);
  }

  Future<void> requestPreviewPlay(
    VideoPlayerController previewController, {
    required bool exclusiveAudio,
  }) async {
    controller._focusEpoch++;
    if (exclusiveAudio) {
      controller._activePlayer = null;
      await _pauseHlsPlayersExcept();
      await _pauseAudioPlayersExcept();
    }
    await _pausePreviewPlayersExcept(previewController);
  }

  Future<void> pauseAllAudioPlayers() async {
    controller._focusEpoch++;
    controller._activePlayer = null;

    await _pauseHlsPlayersExcept();
    await _pausePreviewPlayersExcept();
    await _pauseAudioPlayersExcept();
  }

  Future<void> _pauseHlsPlayersExcept([HLSVideoAdapter? except]) async {
    final others =
        controller._players.where((p) => !identical(p, except)).toList();
    for (final p in others) {
      final samePlaybackResource = except != null && p.url == except.url;
      if (samePlaybackResource) {
        continue;
      }
      try {
        if (defaultTargetPlatform == TargetPlatform.iOS &&
            p.preferWarmPoolPause &&
            !p.value.isPlaying) {
          await p.setVolume(0.0);
          continue;
        }
        await p.forceSilence();
      } catch (_) {}
    }
  }

  Future<void> _pauseAudioPlayersExcept([AudioPlayer? except]) async {
    for (final player in controller._audioPlayers.toList()) {
      if (identical(player, except)) continue;
      try {
        await player.pause();
      } catch (_) {}
    }
  }

  Future<void> _pausePreviewPlayersExcept([
    VideoPlayerController? except,
  ]) async {
    for (final previewController in controller._previewPlayers.toList()) {
      if (identical(previewController, except)) continue;
      try {
        await previewController.pause();
      } catch (_) {}
    }
  }
}
