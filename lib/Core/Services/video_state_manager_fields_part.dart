part of 'video_state_manager.dart';

const int _videoStateManagerMaxTrackedControllers = 30;
const Duration _videoStateManagerPlayResumeDelay = Duration(milliseconds: 140);

class _VideoStateManagerState {
  Map<String, VideoState> videoStates = <String, VideoState>{};
  Map<String, PlaybackHandle> allVideoControllers = <String, PlaybackHandle>{};
  String? currentPlayingDocID;
  bool exclusiveMode = false;
  String? exclusiveDocID;
  Timer? pendingPlayTimer;
  int playRequestSeq = 0;
}

extension VideoStateManagerFieldsPart on VideoStateManager {
  Map<String, VideoState> get _videoStates => _state.videoStates;
  set _videoStates(Map<String, VideoState> value) => _state.videoStates = value;

  Map<String, PlaybackHandle> get _allVideoControllers =>
      _state.allVideoControllers;
  set _allVideoControllers(Map<String, PlaybackHandle> value) =>
      _state.allVideoControllers = value;

  String? get _currentPlayingDocID => _state.currentPlayingDocID;
  set _currentPlayingDocID(String? value) => _state.currentPlayingDocID = value;

  bool get _exclusiveMode => _state.exclusiveMode;
  set _exclusiveMode(bool value) => _state.exclusiveMode = value;

  String? get _exclusiveDocID => _state.exclusiveDocID;
  set _exclusiveDocID(String? value) => _state.exclusiveDocID = value;

  Timer? get _pendingPlayTimer => _state.pendingPlayTimer;
  set _pendingPlayTimer(Timer? value) => _state.pendingPlayTimer = value;

  int get _playRequestSeq => _state.playRequestSeq;
  set _playRequestSeq(int value) => _state.playRequestSeq = value;
}
