part of 'audio_focus_coordinator.dart';

/// Uygulama genelinde tek bir aktif ses kaynağı olmasını zorlar.
class AudioFocusCoordinator extends GetxService {
  static AudioFocusCoordinator? maybeFind() =>
      _maybeFindAudioFocusCoordinator();

  static AudioFocusCoordinator ensure() => _ensureAudioFocusCoordinator();

  static AudioFocusCoordinator get instance {
    return ensure();
  }

  final Set<HLSVideoAdapter> _players = <HLSVideoAdapter>{};
  final Set<AudioPlayer> _audioPlayers = <AudioPlayer>{};
  final Set<VideoPlayerController> _previewPlayers = <VideoPlayerController>{};
  HLSVideoAdapter? _activePlayer;
  int _focusEpoch = 0;

  void register(HLSVideoAdapter player) =>
      _AudioFocusCoordinatorRuntimePart(this).register(player);

  void unregister(HLSVideoAdapter player) =>
      _AudioFocusCoordinatorRuntimePart(this).unregister(player);

  Future<void> requestPlay(HLSVideoAdapter player) =>
      _AudioFocusCoordinatorRuntimePart(this).requestPlay(player);

  void requestPause(HLSVideoAdapter player) =>
      _AudioFocusCoordinatorRuntimePart(this).requestPause(player);

  void registerAudioPlayer(AudioPlayer player) =>
      _AudioFocusCoordinatorRuntimePart(this).registerAudioPlayer(player);

  void unregisterAudioPlayer(AudioPlayer player) =>
      _AudioFocusCoordinatorRuntimePart(this).unregisterAudioPlayer(player);

  void registerPreviewPlayer(VideoPlayerController controller) =>
      _AudioFocusCoordinatorRuntimePart(this).registerPreviewPlayer(controller);

  void unregisterPreviewPlayer(VideoPlayerController controller) =>
      _AudioFocusCoordinatorRuntimePart(this)
          .unregisterPreviewPlayer(controller);

  Future<void> requestAudioPlayerPlay(AudioPlayer player) =>
      _AudioFocusCoordinatorRuntimePart(this).requestAudioPlayerPlay(player);

  Future<void> requestPreviewPlay(
    VideoPlayerController controller, {
    bool exclusiveAudio = true,
  }) =>
      _AudioFocusCoordinatorRuntimePart(this).requestPreviewPlay(
        controller,
        exclusiveAudio: exclusiveAudio,
      );

  Future<void> pauseAllAudioPlayers() =>
      _AudioFocusCoordinatorRuntimePart(this).pauseAllAudioPlayers();
}
