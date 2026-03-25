part of 'progress_indicators.dart';

class UploadProgressController extends GetxController {
  static UploadProgressController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(UploadProgressController(), permanent: permanent);
  }

  static UploadProgressController? maybeFind() {
    final isRegistered = Get.isRegistered<UploadProgressController>();
    if (!isRegistered) return null;
    return Get.find<UploadProgressController>();
  }

  final RxDouble progress = 0.0.obs;
  final RxString status = ''.obs;
  final RxString currentFile = ''.obs;
  final RxInt currentIndex = 0.obs;
  final RxInt totalFiles = 0.obs;
  final RxBool isVisible = false.obs;
  final RxBool isPaused = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  void startProgress({
    required int total,
    required String initialStatus,
  }) {
    totalFiles.value = total;
    currentIndex.value = 0;
    progress.value = 0.0;
    status.value = initialStatus;
    isVisible.value = true;
    isPaused.value = false;
    hasError.value = false;
    errorMessage.value = '';
  }

  void updateProgress({
    required int current,
    required String fileName,
    required String statusText,
    double? progressValue,
  }) {
    currentIndex.value = current;
    currentFile.value = fileName;
    status.value = statusText;

    if (progressValue != null) {
      progress.value = progressValue;
    } else {
      progress.value = current / totalFiles.value;
    }
  }

  void setError(String error) {
    hasError.value = true;
    errorMessage.value = error;
    status.value = 'progress.error_occurred'.tr;
  }

  void complete(String message) {
    progress.value = 1.0;
    status.value = message;
    Future.delayed(const Duration(seconds: 2), () {
      isVisible.value = false;
    });
  }

  void hide() {
    isVisible.value = false;
  }

  void pause() {
    isPaused.value = true;
    status.value = 'progress.paused'.tr;
  }

  void resume() {
    isPaused.value = false;
  }
}
