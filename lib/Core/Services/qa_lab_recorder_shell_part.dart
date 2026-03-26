part of 'qa_lab_recorder.dart';

class QALabRecorder extends GetxService {
  static QALabRecorder ensure() => _ensureQALabRecorder();
  static QALabRecorder? maybeFind() => _maybeFindQALabRecorder();

  final _state = _QALabRecorderState();

  @override
  void onInit() {
    super.onInit();
    _handleQALabRecorderInit(this);
  }

  @override
  void onClose() {
    _handleQALabRecorderClose(this);
    super.onClose();
  }
}
