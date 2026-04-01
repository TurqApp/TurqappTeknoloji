part of 'progress_indicators.dart';

UploadProgressController ensureUploadProgressController({
  bool permanent = false,
}) =>
    _ensureUploadProgressController(permanent: permanent);

UploadProgressController? maybeFindUploadProgressController() =>
    _maybeFindUploadProgressController();

UploadProgressController _ensureUploadProgressController({
  bool permanent = false,
}) =>
    _maybeFindUploadProgressController() ??
    Get.put(UploadProgressController(), permanent: permanent);

UploadProgressController? _maybeFindUploadProgressController() =>
    Get.isRegistered<UploadProgressController>()
        ? Get.find<UploadProgressController>()
        : null;

extension UploadProgressControllerActionsPart on UploadProgressController {
  void startProgress({
    required int total,
    required String initialStatus,
  }) =>
      _startUploadProgress(this, total: total, initialStatus: initialStatus);

  void updateProgress({
    required int current,
    required String fileName,
    required String statusText,
    double? progressValue,
  }) =>
      _updateUploadProgress(
        this,
        current: current,
        fileName: fileName,
        statusText: statusText,
        progressValue: progressValue,
      );

  void setError(String error) => _setUploadProgressError(this, error);

  void complete(String message) => _completeUploadProgress(this, message);

  void hide() => _hideUploadProgress(this);

  void pause() => _pauseUploadProgress(this);

  void resume() => _resumeUploadProgress(this);
}

void _startUploadProgress(
  UploadProgressController controller, {
  required int total,
  required String initialStatus,
}) {
  controller.totalFiles.value = total;
  controller.currentIndex.value = 0;
  controller.progress.value = 0.0;
  controller.status.value = initialStatus;
  controller.isVisible.value = true;
  controller.isPaused.value = false;
  controller.hasError.value = false;
  controller.errorMessage.value = '';
}

void _updateUploadProgress(
  UploadProgressController controller, {
  required int current,
  required String fileName,
  required String statusText,
  double? progressValue,
}) {
  controller.currentIndex.value = current;
  controller.currentFile.value = fileName;
  controller.status.value = statusText;
  controller.progress.value =
      progressValue ?? current / controller.totalFiles.value;
}

void _setUploadProgressError(
  UploadProgressController controller,
  String error,
) {
  controller.hasError.value = true;
  controller.errorMessage.value = error;
  controller.status.value = 'progress.error_occurred'.tr;
}

void _completeUploadProgress(
  UploadProgressController controller,
  String message,
) {
  controller.progress.value = 1.0;
  controller.status.value = message;
  Future.delayed(const Duration(seconds: 2), () {
    controller.isVisible.value = false;
  });
}

void _hideUploadProgress(UploadProgressController controller) {
  controller.isVisible.value = false;
}

void _pauseUploadProgress(UploadProgressController controller) {
  controller.isPaused.value = true;
  controller.status.value = 'progress.paused'.tr;
}

void _resumeUploadProgress(UploadProgressController controller) {
  controller.isPaused.value = false;
}
