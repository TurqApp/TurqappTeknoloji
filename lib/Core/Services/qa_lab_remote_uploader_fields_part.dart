part of 'qa_lab_remote_uploader.dart';

class _QALabRemoteUploaderState {
  final RxString lastSyncState = 'idle'.obs;
  final RxString lastSyncError = ''.obs;
  final RxString lastSyncReason = ''.obs;
  final Rxn<DateTime> lastSyncedAt = Rxn<DateTime>();
  final Rxn<DateTime> lastGateCheckedAt = Rxn<DateTime>();
  final RxBool remoteCollectionEnabled = false.obs;
  final RxInt uploadCount = 0.obs;
  final RxInt uploadedOccurrenceCount = 0.obs;

  Timer? debounceTimer;
  StreamSubscription<Map<String, dynamic>>? qaConfigSubscription;
  bool syncInFlight = false;
  Map<String, dynamic>? pendingSessionDocument;
  String pendingReason = '';
  Map<String, Map<String, dynamic>> pendingOccurrences =
      <String, Map<String, dynamic>>{};
  Set<String> uploadedOccurrenceIds = <String>{};
  String activeSessionId = '';
  DateTime? lastGateRefreshAt;
  DateTime? permissionDeniedUntil;
  String permissionDeniedSessionId = '';
}

extension QALabRemoteUploaderFieldsPart on QALabRemoteUploader {
  RxString get lastSyncState => _state.lastSyncState;
  RxString get lastSyncError => _state.lastSyncError;
  RxString get lastSyncReason => _state.lastSyncReason;
  Rxn<DateTime> get lastSyncedAt => _state.lastSyncedAt;
  Rxn<DateTime> get lastGateCheckedAt => _state.lastGateCheckedAt;
  RxBool get remoteCollectionEnabled => _state.remoteCollectionEnabled;
  RxInt get uploadCount => _state.uploadCount;
  RxInt get uploadedOccurrenceCount => _state.uploadedOccurrenceCount;

  Timer? get _debounceTimer => _state.debounceTimer;
  set _debounceTimer(Timer? value) => _state.debounceTimer = value;

  StreamSubscription<Map<String, dynamic>>? get _qaConfigSubscription =>
      _state.qaConfigSubscription;
  set _qaConfigSubscription(StreamSubscription<Map<String, dynamic>>? value) =>
      _state.qaConfigSubscription = value;

  bool get _syncInFlight => _state.syncInFlight;
  set _syncInFlight(bool value) => _state.syncInFlight = value;

  Map<String, dynamic>? get _pendingSessionDocument =>
      _state.pendingSessionDocument;
  set _pendingSessionDocument(Map<String, dynamic>? value) =>
      _state.pendingSessionDocument = value;

  String get _pendingReason => _state.pendingReason;
  set _pendingReason(String value) => _state.pendingReason = value;

  Map<String, Map<String, dynamic>> get _pendingOccurrences =>
      _state.pendingOccurrences;
  set _pendingOccurrences(Map<String, Map<String, dynamic>> value) =>
      _state.pendingOccurrences = value;

  Set<String> get _uploadedOccurrenceIds => _state.uploadedOccurrenceIds;
  set _uploadedOccurrenceIds(Set<String> value) =>
      _state.uploadedOccurrenceIds = value;

  String get _activeSessionId => _state.activeSessionId;
  set _activeSessionId(String value) => _state.activeSessionId = value;

  DateTime? get _lastGateRefreshAt => _state.lastGateRefreshAt;
  set _lastGateRefreshAt(DateTime? value) => _state.lastGateRefreshAt = value;

  DateTime? get _permissionDeniedUntil => _state.permissionDeniedUntil;
  set _permissionDeniedUntil(DateTime? value) =>
      _state.permissionDeniedUntil = value;

  String get _permissionDeniedSessionId => _state.permissionDeniedSessionId;
  set _permissionDeniedSessionId(String value) =>
      _state.permissionDeniedSessionId = value;
}
