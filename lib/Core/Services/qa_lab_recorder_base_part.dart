part of 'qa_lab_recorder.dart';

abstract class _QALabRecorderBase extends GetxService {
  final _state = _QALabRecorderState();

  @override
  void onInit() {
    super.onInit();
    _handleQALabRecorderInit(this as QALabRecorder);
  }

  @override
  void onClose() {
    _handleQALabRecorderClose(this as QALabRecorder);
    super.onClose();
  }
}
