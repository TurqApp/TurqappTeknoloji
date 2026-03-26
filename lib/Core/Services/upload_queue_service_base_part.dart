part of 'upload_queue_service.dart';

abstract class _UploadQueueServiceBase extends GetxController {
  final _state = _UploadQueueServiceState();

  @override
  void onInit() {
    super.onInit();
    _handleUploadQueueServiceInit(this as UploadQueueService);
  }

  @override
  void onClose() {
    _handleUploadQueueServiceClose(this as UploadQueueService);
    super.onClose();
  }
}
