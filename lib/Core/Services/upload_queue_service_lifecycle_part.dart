part of 'upload_queue_service.dart';

extension _UploadQueueServiceLifecyclePart on UploadQueueService {
  void handleOnInit() {
    _initializeQueuePersistence();
  }

  void handleOnClose() {
    _disposeQueuePersistence();
  }
}
