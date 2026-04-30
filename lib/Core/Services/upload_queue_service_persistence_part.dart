part of 'upload_queue_service.dart';

extension UploadQueueServicePersistencePart on UploadQueueService {
  void _initializeQueuePersistence() {
    _loadQueueFromStorage();
    _listenToConnectivity();
    _authSub ??= CurrentUserService.instance.authStateChanges().listen((_) {
      unawaited(_loadQueueFromStorage());
    });
  }

  void _performPauseQueue() {
    _isPaused.value = true;
    _notifyQueueUpdated();
  }

  void _performResumeQueue() {
    _isPaused.value = false;
    _processQueue();
    _notifyQueueUpdated();
  }

  void _performClearCompleted() async {
    _queue.removeWhere((item) => item.status == UploadStatus.completed);
    _notifyQueueUpdated();
    await _saveQueueToStorage();
  }

  void _performRetryFailed() async {
    for (final upload
        in _queue.where((item) => item.status == UploadStatus.failed)) {
      upload.status = UploadStatus.pending;
      upload.retryCount = 0;
      upload.errorMessage = null;
      upload.progress = 0.0;
    }
    _failedCount.value = 0;
    _notifyQueueUpdated();
    await _saveQueueToStorage();
    _processQueue();
  }

  void _performRemoveUpload(String uploadId) async {
    _queue.removeWhere((item) => item.id == uploadId);
    _notifyQueueUpdated();
    await _saveQueueToStorage();
  }

  Future<void> _performSaveQueueToStorage() async {
    final preferences = ensureLocalPreferenceRepository();
    final queueJson = _queue.map((item) => item.toJson()).toList();
    await preferences.setString(_queueKey, jsonEncode(queueJson));
  }

  Future<void> _performLoadQueueFromStorage() async {
    final preferences = ensureLocalPreferenceRepository();
    final queueString = await preferences.getString(_queueKey);
    _queue.clear();
    _completedCount.value = 0;
    _failedCount.value = 0;

    if (queueString != null) {
      try {
        final decoded = jsonDecode(queueString);
        if (decoded is! List) {
          await preferences.remove(_queueKey);
          return;
        }
        var shouldPrune = false;
        final restored = <QueuedUpload>[];
        for (final item in decoded) {
          if (item is! Map) {
            shouldPrune = true;
            continue;
          }
          try {
            restored.add(
              QueuedUpload.fromJson(
                Map<String, dynamic>.from(item.cast<dynamic, dynamic>()),
              ),
            );
          } catch (_) {
            shouldPrune = true;
          }
        }
        _queue.assignAll(restored);

        for (final upload
            in _queue.where((item) => item.status == UploadStatus.uploading)) {
          upload.status = UploadStatus.pending;
          upload.progress = 0.0;
        }

        _completedCount.value = _queue
            .where((item) => item.status == UploadStatus.completed)
            .length;
        _failedCount.value =
            _queue.where((item) => item.status == UploadStatus.failed).length;

        if (shouldPrune || restored.length != decoded.length) {
          await _saveQueueToStorage();
        }
        _notifyQueueUpdated();
      } catch (_) {
        await preferences.remove(_queueKey);
      }
    }
  }

  void _performListenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork =
          results.any((result) => result != ConnectivityResult.none);
      if (hasNetwork && !_isProcessing.value && !_isPaused.value) {
        _processQueue();
      }
    });
  }

  Map<String, dynamic> _performGetQueueStats() {
    return {
      'total': _queue.length,
      'pending': pendingCount,
      'completed': _completedCount.value,
      'failed': _failedCount.value,
      'processing': _isProcessing.value,
      'paused': _isPaused.value,
    };
  }

  void _disposeQueuePersistence() {
    _authSub?.cancel();
  }
}
