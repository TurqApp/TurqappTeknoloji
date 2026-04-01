part of 'upload_queue_service.dart';

class UploadQueueService extends _UploadQueueServiceBase {
  static UploadQueueService? maybeFind() => _maybeFindUploadQueueService();

  static UploadQueueService ensure({bool permanent = false}) =>
      _ensureUploadQueueService(permanent: permanent);
}
