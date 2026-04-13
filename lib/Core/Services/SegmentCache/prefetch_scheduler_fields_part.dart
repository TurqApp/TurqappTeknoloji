part of 'prefetch_scheduler.dart';

class _PrefetchSchedulerState {
  final List<_PrefetchJob> queue = <_PrefetchJob>[];
  final Map<String, _PrefetchJob> pendingFollowUpJobs =
      <String, _PrefetchJob>{};
  bool paused = false;
  bool mobileSeedMode = false;
  int activeDownloads = 0;
  int activeBankDownloads = 0;
  int pendingDownloadBytes = 0;
  final Map<String, DateTime> jobEnqueuedAt = <String, DateTime>{};
  final Map<String, int> activeDocRefCounts = <String, int>{};
  final Set<String> activeBankDocIDs = <String>{};
  List<String> lastPriorityDocIDs = const <String>[];
  int lastPriorityCurrentIndex = 0;
  List<String> lastFeedDocIDs = const <String>[];
  List<String> lastFeedSurfaceVideoDocIDs = const <String>[];
  List<String> lastFeedBankDocIDs = const <String>[];
  String? focusedDocID;
  bool restrictToFocusedDoc = false;
  int lastFeedCurrentIndex = 0;
  int lastFeedReadyCount = 0;
  int lastFeedWindowCount = 0;
  double lastFeedReadyRatio = 0.0;
  int queueLatencySamples = 0;
  double avgQueueDispatchLatencyMs = 0.0;
  String? lastPrefetchHealthSignature;
  DownloadWorker? worker;
  StreamSubscription? workerSub;
  Timer? watchdogTimer;
  final http.Client httpClient = http.Client();
  bool quotaFillRemoteInFlight = false;
  bool quotaFillRemoteHasMore = true;
  QueryDocumentSnapshot<Map<String, dynamic>>? quotaFillRemoteCursor;
  int quotaFillRemoteExhaustedUsageBytes = 0;
  int quotaFillRemoteExhaustedTargetBytes = 0;
  bool automaticQuotaFillEnabled = true;
}

extension _PrefetchSchedulerFieldsPart on PrefetchScheduler {
  List<_PrefetchJob> get _queue => _state.queue;
  Map<String, _PrefetchJob> get _pendingFollowUpJobs =>
      _state.pendingFollowUpJobs;
  bool get _paused => _state.paused;
  set _paused(bool value) => _state.paused = value;
  bool get _mobileSeedMode => _state.mobileSeedMode;
  set _mobileSeedMode(bool value) => _state.mobileSeedMode = value;
  int get _activeDownloads => _state.activeDownloads;
  set _activeDownloads(int value) => _state.activeDownloads = value;
  int get _activeBankDownloads => _state.activeBankDownloads;
  set _activeBankDownloads(int value) => _state.activeBankDownloads = value;
  int get _pendingDownloadBytes => _state.pendingDownloadBytes;
  set _pendingDownloadBytes(int value) => _state.pendingDownloadBytes = value;
  Map<String, DateTime> get _jobEnqueuedAt => _state.jobEnqueuedAt;
  Map<String, int> get _activeDocRefCounts => _state.activeDocRefCounts;
  Set<String> get _activeBankDocIDs => _state.activeBankDocIDs;
  List<String> get _lastPriorityDocIDs => _state.lastPriorityDocIDs;
  set _lastPriorityDocIDs(List<String> value) =>
      _state.lastPriorityDocIDs = value;
  int get _lastPriorityCurrentIndex => _state.lastPriorityCurrentIndex;
  set _lastPriorityCurrentIndex(int value) =>
      _state.lastPriorityCurrentIndex = value;
  List<String> get _lastFeedDocIDs => _state.lastFeedDocIDs;
  set _lastFeedDocIDs(List<String> value) => _state.lastFeedDocIDs = value;
  List<String> get _lastFeedSurfaceVideoDocIDs =>
      _state.lastFeedSurfaceVideoDocIDs;
  set _lastFeedSurfaceVideoDocIDs(List<String> value) =>
      _state.lastFeedSurfaceVideoDocIDs = value;
  List<String> get _lastFeedBankDocIDs => _state.lastFeedBankDocIDs;
  set _lastFeedBankDocIDs(List<String> value) =>
      _state.lastFeedBankDocIDs = value;
  String? get _focusedDocID => _state.focusedDocID;
  set _focusedDocID(String? value) => _state.focusedDocID = value;
  bool get _restrictToFocusedDoc => _state.restrictToFocusedDoc;
  set _restrictToFocusedDoc(bool value) => _state.restrictToFocusedDoc = value;
  int get _lastFeedCurrentIndex => _state.lastFeedCurrentIndex;
  set _lastFeedCurrentIndex(int value) => _state.lastFeedCurrentIndex = value;
  int get _lastFeedReadyCount => _state.lastFeedReadyCount;
  set _lastFeedReadyCount(int value) => _state.lastFeedReadyCount = value;
  int get _lastFeedWindowCount => _state.lastFeedWindowCount;
  set _lastFeedWindowCount(int value) => _state.lastFeedWindowCount = value;
  double get _lastFeedReadyRatio => _state.lastFeedReadyRatio;
  set _lastFeedReadyRatio(double value) => _state.lastFeedReadyRatio = value;
  int get _queueLatencySamples => _state.queueLatencySamples;
  set _queueLatencySamples(int value) => _state.queueLatencySamples = value;
  double get _avgQueueDispatchLatencyMs => _state.avgQueueDispatchLatencyMs;
  set _avgQueueDispatchLatencyMs(double value) =>
      _state.avgQueueDispatchLatencyMs = value;
  String? get _lastPrefetchHealthSignature =>
      _state.lastPrefetchHealthSignature;
  set _lastPrefetchHealthSignature(String? value) =>
      _state.lastPrefetchHealthSignature = value;
  DownloadWorker? get _worker => _state.worker;
  set _worker(DownloadWorker? value) => _state.worker = value;
  StreamSubscription? get _workerSub => _state.workerSub;
  set _workerSub(StreamSubscription? value) => _state.workerSub = value;
  Timer? get _watchdogTimer => _state.watchdogTimer;
  set _watchdogTimer(Timer? value) => _state.watchdogTimer = value;
  http.Client get _httpClient => _state.httpClient;
  bool get _quotaFillRemoteInFlight => _state.quotaFillRemoteInFlight;
  set _quotaFillRemoteInFlight(bool value) =>
      _state.quotaFillRemoteInFlight = value;
  bool get _quotaFillRemoteHasMore => _state.quotaFillRemoteHasMore;
  set _quotaFillRemoteHasMore(bool value) =>
      _state.quotaFillRemoteHasMore = value;
  QueryDocumentSnapshot<Map<String, dynamic>>? get _quotaFillRemoteCursor =>
      _state.quotaFillRemoteCursor;
  set _quotaFillRemoteCursor(QueryDocumentSnapshot<Map<String, dynamic>>? value) =>
      _state.quotaFillRemoteCursor = value;
  int get _quotaFillRemoteExhaustedUsageBytes =>
      _state.quotaFillRemoteExhaustedUsageBytes;
  set _quotaFillRemoteExhaustedUsageBytes(int value) =>
      _state.quotaFillRemoteExhaustedUsageBytes = value;
  int get _quotaFillRemoteExhaustedTargetBytes =>
      _state.quotaFillRemoteExhaustedTargetBytes;
  set _quotaFillRemoteExhaustedTargetBytes(int value) =>
      _state.quotaFillRemoteExhaustedTargetBytes = value;
  bool get _automaticQuotaFillEnabled => _state.automaticQuotaFillEnabled;
}
