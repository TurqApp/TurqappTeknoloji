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
      final decoded = jsonDecode(json);
      if (decoded is! List) {
        await _prefs?.remove(_deadLetterActionsKey);
        return;
      }
      var shouldPrune = false;
      final restored = <PendingAction>[];
      for (final item in decoded) {
        if (item is! Map) {
          shouldPrune = true;
          continue;
        }
        try {
          restored.add(
            PendingAction.fromJson(
              Map<String, dynamic>.from(item.cast<dynamic, dynamic>()),
            ),
          );
        } catch (_) {
          shouldPrune = true;
        }
      }
      deadLetterActions.value = restored;
      if (shouldPrune) {
        await _saveDeadLetterActions();
      }
    } catch (e) {
      print('❌ Failed to load dead-letter actions: $e');
      await _prefs?.remove(_deadLetterActionsKey);
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

      final decoded = jsonDecode(json);
      if (decoded is! List) {
        await _prefs?.remove(_pendingActionsKey);
        return;
      }
      var shouldPrune = false;
      final restored = <PendingAction>[];
      for (final item in decoded) {
        if (item is! Map) {
          shouldPrune = true;
          continue;
        }
        try {
          restored.add(
            PendingAction.fromJson(
              Map<String, dynamic>.from(item.cast<dynamic, dynamic>()),
            ),
          );
        } catch (_) {
          shouldPrune = true;
        }
      }
      pendingActions.value = restored;
      if (shouldPrune) {
        await _savePendingActions();
      }

      print('📂 Loaded ${pendingActions.length} pending actions');
    } catch (e) {
      print('❌ Failed to load pending actions: $e');
      await _prefs?.remove(_pendingActionsKey);
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
