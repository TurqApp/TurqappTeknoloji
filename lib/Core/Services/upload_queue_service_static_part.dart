part of 'upload_queue_service.dart';

UploadQueueService? _maybeFindUploadQueueService() {
  final isRegistered = Get.isRegistered<UploadQueueService>();
  if (!isRegistered) return null;
  return Get.find<UploadQueueService>();
}

UploadQueueService _ensureUploadQueueService({bool permanent = false}) {
  final existing = _maybeFindUploadQueueService();
  if (existing != null) return existing;
  return Get.put(UploadQueueService(), permanent: permanent);
}

void _handleUploadQueueServiceInit(UploadQueueService service) {
  _UploadQueueServiceLifecyclePart(service).handleOnInit();
}

void _handleUploadQueueServiceClose(UploadQueueService service) {
  _UploadQueueServiceLifecyclePart(service).handleOnClose();
}

Future<void> _createUploadPendingPostShell(
  UploadQueueService service,
  QueuedUpload upload,
) =>
    service._performCreatePendingPostShell(upload);

Future<void> _saveUploadQueueToStorage(UploadQueueService service) =>
    service._performSaveQueueToStorage();

Future<void> _loadUploadQueueFromStorage(UploadQueueService service) =>
    service._performLoadQueueFromStorage();
