part of 'upload_queue_service.dart';

extension UploadQueueServicePostShellPart on UploadQueueService {
  Future<void> _performCreatePendingPostShell(QueuedUpload upload) =>
      _performCreatePendingPostShellContent(upload);
}
