part of 'upload_queue_service.dart';

extension UploadQueueServiceFacadePart on UploadQueueService {
  List<QueuedUpload> get queue => _queue;
  bool get isProcessing => _isProcessing.value;
  bool get isPaused => _isPaused.value;
  int get failedCount => _failedCount.value;
  int get completedCount => _completedCount.value;
  int get pendingCount =>
      _queue.where((item) => item.status == UploadStatus.pending).length;

  void _processQueue() => _performProcessQueue();

  Future<void> _processUpload(QueuedUpload upload) =>
      _performProcessUpload(upload);

  void pauseQueue() => _performPauseQueue();

  void resumeQueue() => _performResumeQueue();

  void clearCompleted() => _performClearCompleted();

  void retryFailed() => _performRetryFailed();

  void removeUpload(String uploadId) => _performRemoveUpload(uploadId);

  void _listenToConnectivity() => _performListenToConnectivity();

  Map<String, dynamic> getQueueStats() => _performGetQueueStats();
}
