part of 'qa_lab_recorder.dart';

extension QALabRecorderFacadePart on QALabRecorder {
  void startSession({String trigger = 'manual'}) =>
      _startSessionImpl(trigger: trigger);
  Future<void> prepareFreshStart({String trigger = 'launch'}) =>
      _prepareFreshStartImpl(trigger: trigger);
  void resetSession() => _resetSessionImpl();
  void disposeSession() => _disposeSessionImpl();
}
