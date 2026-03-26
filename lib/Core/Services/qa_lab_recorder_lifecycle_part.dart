part of 'qa_lab_recorder.dart';

QALabRecorder _ensureQALabRecorder() =>
    _maybeFindQALabRecorder() ?? Get.put(QALabRecorder(), permanent: true);

QALabRecorder? _maybeFindQALabRecorder() =>
    Get.isRegistered<QALabRecorder>() ? Get.find<QALabRecorder>() : null;

void _handleQALabRecorderInit(QALabRecorder controller) {
  if (QALabMode.autoStartSession) {
    controller._startSessionImpl(trigger: 'auto');
  }
}

void _handleQALabRecorderClose(QALabRecorder controller) {
  controller._disposeSessionImpl();
}
