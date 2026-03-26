part of 'audio_focus_coordinator.dart';

abstract class _AudioFocusCoordinatorBase extends GetxService {
  final Set<HLSVideoAdapter> _players = <HLSVideoAdapter>{};
  final Set<AudioPlayer> _audioPlayers = <AudioPlayer>{};
  final Set<VideoPlayerController> _previewPlayers = <VideoPlayerController>{};
  HLSVideoAdapter? _activePlayer;
  int _focusEpoch = 0;
}
