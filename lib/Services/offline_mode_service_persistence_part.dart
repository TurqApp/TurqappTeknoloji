part of 'offline_mode_service.dart';

extension OfflineModeServicePersistencePart on OfflineModeService {
  void _loadStats() {
    final rawLastSync = _prefs?.getInt(_lastSyncAtKey) ?? 0;
    if (rawLastSync > 0) {
      lastSyncAt.value = DateTime.fromMillisecondsSinceEpoch(rawLastSync);
    }
    processedCount.value = _prefs?.getInt(_processedCountKey) ?? 0;
    failedCount.value = _prefs?.getInt(_failedCountKey) ?? 0;
  }

  Future<void> _saveStats() async {
    final syncMs = lastSyncAt.value?.millisecondsSinceEpoch ?? 0;
    await _prefs?.setInt(_lastSyncAtKey, syncMs);
    await _prefs?.setInt(_processedCountKey, processedCount.value);
    await _prefs?.setInt(_failedCountKey, failedCount.value);
  }

  Future<void> _loadDeadLetterActions() async {
    try {
      final json = _prefs?.getString(_deadLetterActionsKey);
      if (json == null) return;
      final List<dynamic> list = jsonDecode(json);
      deadLetterActions.value =
          list.map((e) => PendingAction.fromJson(e)).toList();
    } catch (e) {
      print('❌ Failed to load dead-letter actions: $e');
    }
  }

  Future<void> _saveDeadLetterActions() async {
    try {
      final json = jsonEncode(
        deadLetterActions.map((e) => e.toJson()).toList(),
      );
      await _prefs?.setString(_deadLetterActionsKey, json);
    } catch (e) {
      print('❌ Failed to save dead-letter actions: $e');
    }
  }

  Future<void> _loadPendingActions() async {
    try {
      final json = _prefs?.getString(_pendingActionsKey);
      if (json == null) return;

      final List<dynamic> list = jsonDecode(json);
      pendingActions.value =
          list.map((e) => PendingAction.fromJson(e)).toList();

      print('📂 Loaded ${pendingActions.length} pending actions');
    } catch (e) {
      print('❌ Failed to load pending actions: $e');
    }
  }

  Future<void> _savePendingActions() async {
    try {
      final json = jsonEncode(
        pendingActions.map((e) => e.toJson()).toList(),
      );
      await _prefs?.setString(_pendingActionsKey, json);
    } catch (e) {
      print('❌ Failed to save pending actions: $e');
    }
  }

  void _disposeOfflineMode() {
    _connectivitySubscription?.cancel();
    _authSubscription?.cancel();
    _retryTimer?.cancel();
  }
}
