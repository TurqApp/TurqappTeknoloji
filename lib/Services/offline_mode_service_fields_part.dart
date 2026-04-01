part of 'offline_mode_service.dart';

class _OfflineModeServiceState {
  final isOnline = true.obs;
  final isSyncing = false.obs;
  final lastSyncAt = Rxn<DateTime>();
  final processedCount = 0.obs;
  final failedCount = 0.obs;
  final pendingActions = <PendingAction>[].obs;
  final deadLetterActions = <PendingAction>[].obs;
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;
  StreamSubscription<User?>? authSubscription;
  Timer? retryTimer;
  SharedPreferences? prefs;
  bool isProcessing = false;
}

extension OfflineModeServiceFieldsPart on OfflineModeService {
  RxBool get isOnline => _state.isOnline;
  RxBool get isSyncing => _state.isSyncing;
  Rxn<DateTime> get lastSyncAt => _state.lastSyncAt;
  RxInt get processedCount => _state.processedCount;
  RxInt get failedCount => _state.failedCount;
  RxList<PendingAction> get pendingActions => _state.pendingActions;
  RxList<PendingAction> get deadLetterActions => _state.deadLetterActions;
  StreamSubscription<List<ConnectivityResult>>? get _connectivitySubscription =>
      _state.connectivitySubscription;
  set _connectivitySubscription(
    StreamSubscription<List<ConnectivityResult>>? value,
  ) =>
      _state.connectivitySubscription = value;
  StreamSubscription<User?>? get _authSubscription => _state.authSubscription;
  set _authSubscription(StreamSubscription<User?>? value) =>
      _state.authSubscription = value;
  Timer? get _retryTimer => _state.retryTimer;
  set _retryTimer(Timer? value) => _state.retryTimer = value;
  SharedPreferences? get _prefs => _state.prefs;
  set _prefs(SharedPreferences? value) => _state.prefs = value;
  bool get _isProcessing => _state.isProcessing;
  set _isProcessing(bool value) => _state.isProcessing = value;
}
