part of 'qa_lab_recorder.dart';

class QALabRecorder extends _QALabRecorderBase {
  static QALabRecorder ensure() => _ensureQALabRecorder();
  static QALabRecorder? maybeFind() => _maybeFindQALabRecorder();
}
