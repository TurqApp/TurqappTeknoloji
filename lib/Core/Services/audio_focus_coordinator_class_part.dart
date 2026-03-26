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
}
