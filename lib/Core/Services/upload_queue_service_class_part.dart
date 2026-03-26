part of 'upload_queue_service.dart';

class UploadQueueService extends GetxController {
  static UploadQueueService? maybeFind() => _maybeFindUploadQueueService();

  static UploadQueueService ensure({bool permanent = false}) =>
      _ensureUploadQueueService(permanent: permanent);

  final _state = _UploadQueueServiceState();

  @override
  void onInit() {
    super.onInit();
    _handleUploadQueueServiceInit(this);
  }

  @override
  void onClose() {
    _handleUploadQueueServiceClose(this);
    super.onClose();
  }
}
