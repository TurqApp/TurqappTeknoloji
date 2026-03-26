part of 'upload_queue_service.dart';

class _UploadQueueServiceState {
  final RxList<QueuedUpload> queue = <QueuedUpload>[].obs;
  final RxBool isProcessing = false.obs;
  final RxBool isPaused = false.obs;
  final RxInt failedCount = 0.obs;
  final RxInt completedCount = 0.obs;
  StreamSubscription<User?>? authSub;
}

extension UploadQueueServiceFieldsPart on UploadQueueService {
  RxList<QueuedUpload> get _queue => _state.queue;
  RxBool get _isProcessing => _state.isProcessing;
  RxBool get _isPaused => _state.isPaused;
  RxInt get _failedCount => _state.failedCount;
  RxInt get _completedCount => _state.completedCount;
  StreamSubscription<User?>? get _authSub => _state.authSub;
  set _authSub(StreamSubscription<User?>? value) => _state.authSub = value;

  void _notifyQueueUpdated() {
    _queue.refresh();
  }
}
