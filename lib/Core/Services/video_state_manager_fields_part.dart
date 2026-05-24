part of 'video_state_manager.dart';

const int _videoStateManagerMaxTrackedControllers = 30;
const Duration _videoStateManagerPlayResumeDelay = Duration(milliseconds: 80);

class _VideoStateManagerState {
  Map<String, VideoState> videoStates = <String, VideoState>{};
  Map<String, PlaybackHandle> allVideoControllers = <String, PlaybackHandle>{};
  Map<String, int> externalOnDemandFetchClaims = <String, int>{};
  final Set<String> transitionResumeResetKeys = <String>{};
  final Map<String, DateTime> transitionResumeResetMarkedAt =
      <String, DateTime>{};
  final Map<String, String> transitionResumeResetReasons = <String, String>{};
  final Map<String, DateTime> androidFeedResumeRecoverUntil =
      <String, DateTime>{};
  FeedPlaybackBackstopSnapshotResolver? feedBackstopSnapshotResolver;
  String? currentPlayingDocID;
  String? targetPlaybackDocID;
  DateTime? targetPlaybackUpdatedAt;
  DateTime? feedRefreshHandoffUntil;
  bool exclusiveMode = false;
  String? exclusiveDocID;
  Timer? pendingPlayTimer;
  Timer? staleStateCleanupTimer;
  int playRequestSeq = 0;
}

extension VideoStateManagerFieldsPart on VideoStateManager {
  PlaybackExecutionService get _playbackExecutionService =>
      const PlaybackExecutionService();

  Map<String, VideoState> get _videoStates => _state.videoStates;

  Map<String, PlaybackHandle> get _allVideoControllers =>
      _state.allVideoControllers;

  Map<String, int> get _externalOnDemandFetchClaims =>
      _state.externalOnDemandFetchClaims;

  Set<String> get _transitionResumeResetKeys =>
      _state.transitionResumeResetKeys;

  Map<String, DateTime> get _transitionResumeResetMarkedAt =>
      _state.transitionResumeResetMarkedAt;

  Map<String, String> get _transitionResumeResetReasons =>
      _state.transitionResumeResetReasons;

  Map<String, DateTime> get _androidFeedResumeRecoverUntil =>
      _state.androidFeedResumeRecoverUntil;

  FeedPlaybackBackstopSnapshotResolver? get _feedBackstopSnapshotResolver =>
      _state.feedBackstopSnapshotResolver;
  set _feedBackstopSnapshotResolver(
    FeedPlaybackBackstopSnapshotResolver? value,
  ) =>
      _state.feedBackstopSnapshotResolver = value;

  String? get _currentPlayingDocID => _state.currentPlayingDocID;
  set _currentPlayingDocID(String? value) => _state.currentPlayingDocID = value;

  String? get _targetPlaybackDocID => _state.targetPlaybackDocID;
  set _targetPlaybackDocID(String? value) => _state.targetPlaybackDocID = value;

  DateTime? get _targetPlaybackUpdatedAt => _state.targetPlaybackUpdatedAt;
  set _targetPlaybackUpdatedAt(DateTime? value) =>
      _state.targetPlaybackUpdatedAt = value;

  DateTime? get _feedRefreshHandoffUntil => _state.feedRefreshHandoffUntil;
  set _feedRefreshHandoffUntil(DateTime? value) =>
      _state.feedRefreshHandoffUntil = value;

  bool get _exclusiveMode => _state.exclusiveMode;
  set _exclusiveMode(bool value) => _state.exclusiveMode = value;

  String? get _exclusiveDocID => _state.exclusiveDocID;
  set _exclusiveDocID(String? value) => _state.exclusiveDocID = value;

  Timer? get _pendingPlayTimer => _state.pendingPlayTimer;
  set _pendingPlayTimer(Timer? value) => _state.pendingPlayTimer = value;

  Timer? get _staleStateCleanupTimer => _state.staleStateCleanupTimer;
  set _staleStateCleanupTimer(Timer? value) =>
      _state.staleStateCleanupTimer = value;

  int get _playRequestSeq => _state.playRequestSeq;
  set _playRequestSeq(int value) => _state.playRequestSeq = value;
}
