part of 'qa_lab_remote_uploader.dart';

class QALabRemoteUploader extends GetxService {
  QALabRemoteUploader({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestoreOverride = firestore,
        _authOverride = auth,
        _state = _QALabRemoteUploaderState();

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;
  final _QALabRemoteUploaderState _state;

  @override
  void onClose() {
    QALabRemoteUploaderRuntimePart(this).onClose();
    super.onClose();
  }
}
