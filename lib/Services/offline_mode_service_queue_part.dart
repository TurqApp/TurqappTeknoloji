part of 'offline_mode_service.dart';

extension OfflineModeServiceQueuePart on OfflineModeService {
  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPendingActions();
    await _loadDeadLetterActions();
    _loadStats();
    _startConnectivityListener();
    _authSubscription ??=
        CurrentUserService.instance.authStateChanges().listen((_) {
      unawaited(_reloadForActiveUser());
    });
  }

  Future<void> _reloadForActiveUser() async {
    pendingActions.clear();
    deadLetterActions.clear();
    processedCount.value = 0;
    failedCount.value = 0;
    lastSyncAt.value = null;
    await _loadPendingActions();
    await _loadDeadLetterActions();
    _loadStats();
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final wasOffline = !isOnline.value;
      isOnline.value =
          results.any((result) => result != ConnectivityResult.none);

      if (wasOffline && isOnline.value) {
        processPendingNow();
      }
    });

    Connectivity().checkConnectivity().then((results) async {
      isOnline.value =
          results.any((result) => result != ConnectivityResult.none);
      if (isOnline.value) {
        await processPendingNow();
      }
    });

    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!isOnline.value) return;
      if (pendingActions.isEmpty) return;
      await processPendingNow();
    });
  }

  Future<void> queueAction(PendingAction action) async {
    final prepared = action.copyWith(
      attemptCount: 0,
      nextAttemptAtMs: 0,
      lastError: null,
      lastTriedAtMs: 0,
    );
    if (action.dedupeKey != null && action.dedupeKey!.isNotEmpty) {
      pendingActions.removeWhere((a) => a.dedupeKey == action.dedupeKey);
      deadLetterActions.removeWhere((a) => a.dedupeKey == action.dedupeKey);
    }
    pendingActions.add(prepared);
    await _savePendingActions();
    await _saveDeadLetterActions();
    print('📥 Queued action: ${action.type} (offline)');
  }

  Future<void> processPendingNow({bool ignoreBackoff = false}) async {
    await _processPendingActions(ignoreBackoff: ignoreBackoff);
  }

  Future<void> retryDeadLetter({int limit = 50}) async {
    if (deadLetterActions.isEmpty) return;
    final take = deadLetterActions.take(limit).toList();
    if (take.isEmpty) return;
    for (final action in take) {
      deadLetterActions.remove(action);
      pendingActions.add(action.copyWith(
        attemptCount: 0,
        nextAttemptAtMs: 0,
        lastError: null,
        lastTriedAtMs: 0,
      ));
    }
    await _savePendingActions();
    await _saveDeadLetterActions();
    await processPendingNow(ignoreBackoff: true);
  }

  Future<void> clearDeadLetter() async {
    deadLetterActions.clear();
    await _saveDeadLetterActions();
  }

  Map<String, dynamic> getQueueStats() {
    return {
      'isOnline': isOnline.value,
      'isSyncing': isSyncing.value,
      'pending': pendingActions.length,
      'deadLetter': deadLetterActions.length,
      'processedCount': processedCount.value,
      'failedCount': failedCount.value,
      'lastSyncAt': lastSyncAt.value?.millisecondsSinceEpoch,
    };
  }

  Future<void> _processPendingActions({bool ignoreBackoff = false}) async {
    if (_isProcessing) return;
    if (pendingActions.isEmpty) return;
    if (!isOnline.value) return;
    _isProcessing = true;
    isSyncing.value = true;
    try {
      print('🔄 Processing ${pendingActions.length} pending actions...');

      final actionsToProcess = List<PendingAction>.from(pendingActions)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      pendingActions.clear();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      var succeeded = 0;

      for (final action in actionsToProcess) {
        if (!ignoreBackoff &&
            action.nextAttemptAtMs > 0 &&
            action.nextAttemptAtMs > nowMs) {
          pendingActions.add(action);
          continue;
        }

        try {
          await action.execute();
          print('✅ Processed: ${action.type}');
          succeeded++;
          processedCount.value++;
        } catch (e) {
          print('❌ Failed to process ${action.type}: $e');
          failedCount.value++;
          final attempts = action.attemptCount + 1;
          if (attempts >= OfflineModeService._maxRetryAttempts) {
            deadLetterActions.add(action.copyWith(
              attemptCount: attempts,
              lastError: e.toString(),
              lastTriedAtMs: nowMs,
              nextAttemptAtMs: 0,
            ));
            continue;
          }
          final backoffMs = _retryDelayMs(attempts);
          pendingActions.add(action.copyWith(
            attemptCount: attempts,
            lastError: e.toString(),
            lastTriedAtMs: nowMs,
            nextAttemptAtMs: nowMs + backoffMs,
          ));
        }
      }

      if (succeeded > 0) {
        lastSyncAt.value = DateTime.now();
      }

      await _savePendingActions();
      await _saveDeadLetterActions();
      await _saveStats();
    } finally {
      isSyncing.value = false;
      _isProcessing = false;
    }
  }

  int _retryDelayMs(int attempt) {
    final factor = 1 << (attempt - 1).clamp(0, 10);
    final delay = OfflineModeService._baseRetryDelayMs * factor;
    return delay > OfflineModeService._maxRetryDelayMs
        ? OfflineModeService._maxRetryDelayMs
        : delay;
  }
}
