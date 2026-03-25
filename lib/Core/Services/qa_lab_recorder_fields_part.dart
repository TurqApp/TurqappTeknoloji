part of 'qa_lab_recorder.dart';

class _QALabRecorderState {
  final sessionId = ''.obs;
  final lastRoute = ''.obs;
  final lastSurface = ''.obs;
  final startedAt = Rxn<DateTime>();
  final lastExportPath = ''.obs;
  final lastLifecycleState = ''.obs;
  final lastPermissionStatuses = <String, String>{}.obs;
  final issues = <QALabIssue>[].obs;
  final routes = <QALabRouteEvent>[].obs;
  final checkpoints = <QALabCheckpoint>[].obs;
  final timelineEvents = <QALabTimelineEvent>[].obs;
  final lastNativePlaybackSnapshot = <String, dynamic>{}.obs;
  final nativePlaybackSamples = <Map<String, dynamic>>[].obs;
  Timer? periodicTimer;
  Timer? nativePlaybackTimer;
  final surfaceWatchdogs = <String, Timer>{};
  final rateLimitedIssueTimes = <String, DateTime>{};
  final emittedFindingKeys = <String>{};
  DateTime? lastAutoExportAt;
  DateTime? lastNativePlaybackSampleAt;
  Map<String, dynamic>? cachedExtendedDeviceInfo;
  Future<Map<String, dynamic>>? extendedDeviceInfoFuture;
  bool autoExportInFlight = false;
  bool nativePlaybackSampleInFlight = false;
}

extension QALabRecorderFieldsPart on QALabRecorder {
  RxString get sessionId => _state.sessionId;
  RxString get lastRoute => _state.lastRoute;
  RxString get lastSurface => _state.lastSurface;
  Rxn<DateTime> get startedAt => _state.startedAt;
  RxString get lastExportPath => _state.lastExportPath;
  RxString get lastLifecycleState => _state.lastLifecycleState;
  RxMap<String, String> get lastPermissionStatuses =>
      _state.lastPermissionStatuses;
  RxList<QALabIssue> get issues => _state.issues;
  RxList<QALabRouteEvent> get routes => _state.routes;
  RxList<QALabCheckpoint> get checkpoints => _state.checkpoints;
  RxList<QALabTimelineEvent> get timelineEvents => _state.timelineEvents;
  RxMap<String, dynamic> get lastNativePlaybackSnapshot =>
      _state.lastNativePlaybackSnapshot;
  RxList<Map<String, dynamic>> get nativePlaybackSamples =>
      _state.nativePlaybackSamples;
  Timer? get _periodicTimer => _state.periodicTimer;
  set _periodicTimer(Timer? value) => _state.periodicTimer = value;
  Timer? get _nativePlaybackTimer => _state.nativePlaybackTimer;
  set _nativePlaybackTimer(Timer? value) => _state.nativePlaybackTimer = value;
  Map<String, Timer> get _surfaceWatchdogs => _state.surfaceWatchdogs;
  Map<String, DateTime> get _rateLimitedIssueTimes =>
      _state.rateLimitedIssueTimes;
  Set<String> get _emittedFindingKeys => _state.emittedFindingKeys;
  DateTime? get _lastAutoExportAt => _state.lastAutoExportAt;
  set _lastAutoExportAt(DateTime? value) => _state.lastAutoExportAt = value;
  DateTime? get _lastNativePlaybackSampleAt =>
      _state.lastNativePlaybackSampleAt;
  set _lastNativePlaybackSampleAt(DateTime? value) =>
      _state.lastNativePlaybackSampleAt = value;
  Map<String, dynamic>? get _cachedExtendedDeviceInfo =>
      _state.cachedExtendedDeviceInfo;
  set _cachedExtendedDeviceInfo(Map<String, dynamic>? value) =>
      _state.cachedExtendedDeviceInfo = value;
  Future<Map<String, dynamic>>? get _extendedDeviceInfoFuture =>
      _state.extendedDeviceInfoFuture;
  set _extendedDeviceInfoFuture(Future<Map<String, dynamic>>? value) =>
      _state.extendedDeviceInfoFuture = value;
  bool get _autoExportInFlight => _state.autoExportInFlight;
  set _autoExportInFlight(bool value) => _state.autoExportInFlight = value;
  bool get _nativePlaybackSampleInFlight => _state.nativePlaybackSampleInFlight;
  set _nativePlaybackSampleInFlight(bool value) =>
      _state.nativePlaybackSampleInFlight = value;
}
