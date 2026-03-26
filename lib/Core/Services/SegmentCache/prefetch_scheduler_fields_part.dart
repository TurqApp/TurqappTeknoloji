part of 'prefetch_scheduler.dart';

class _PrefetchSchedulerState {
  final List<_PrefetchJob> queue = <_PrefetchJob>[];
  bool paused = false;
  bool mobileSeedMode = false;
  int activeDownloads = 0;
  int pendingDownloadBytes = 0;
  final Map<String, DateTime> jobEnqueuedAt = <String, DateTime>{};
  List<String> lastFeedDocIDs = const <String>[];
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
}

extension _PrefetchSchedulerFieldsPart on PrefetchScheduler {
  List<_PrefetchJob> get _queue => _state.queue;
  bool get _paused => _state.paused;
  set _paused(bool value) => _state.paused = value;
  bool get _mobileSeedMode => _state.mobileSeedMode;
  set _mobileSeedMode(bool value) => _state.mobileSeedMode = value;
  int get _activeDownloads => _state.activeDownloads;
  set _activeDownloads(int value) => _state.activeDownloads = value;
  int get _pendingDownloadBytes => _state.pendingDownloadBytes;
  set _pendingDownloadBytes(int value) => _state.pendingDownloadBytes = value;
  Map<String, DateTime> get _jobEnqueuedAt => _state.jobEnqueuedAt;
  List<String> get _lastFeedDocIDs => _state.lastFeedDocIDs;
  set _lastFeedDocIDs(List<String> value) => _state.lastFeedDocIDs = value;
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
}
