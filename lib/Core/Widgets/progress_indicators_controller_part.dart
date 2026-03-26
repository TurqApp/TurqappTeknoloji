part of 'progress_indicators.dart';

class UploadProgressController extends GetxController {
  static UploadProgressController ensure({bool permanent = false}) =>
      _ensureUploadProgressController(permanent: permanent);

  static UploadProgressController? maybeFind() =>
      _maybeFindUploadProgressController();

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
  }) =>
      _startUploadProgress(
        this,
        total: total,
        initialStatus: initialStatus,
      );

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
