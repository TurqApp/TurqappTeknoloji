part of 'progress_indicators.dart';

class _UploadProgressControllerState {
  final RxDouble progress = 0.0.obs;
  final RxString status = ''.obs;
  final RxString currentFile = ''.obs;
  final RxInt currentIndex = 0.obs;
  final RxInt totalFiles = 0.obs;
  final RxBool isVisible = false.obs;
  final RxBool isPaused = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
}

extension UploadProgressControllerFieldsPart on UploadProgressController {
  RxDouble get progress => _state.progress;
  RxString get status => _state.status;
  RxString get currentFile => _state.currentFile;
  RxInt get currentIndex => _state.currentIndex;
  RxInt get totalFiles => _state.totalFiles;
  RxBool get isVisible => _state.isVisible;
  RxBool get isPaused => _state.isPaused;
  RxBool get hasError => _state.hasError;
  RxString get errorMessage => _state.errorMessage;
}
