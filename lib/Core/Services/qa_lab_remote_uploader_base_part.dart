part of 'qa_lab_remote_uploader.dart';

abstract class _QALabRemoteUploaderBase extends GetxService {
  _QALabRemoteUploaderBase({
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
    QALabRemoteUploaderRuntimePart(this as QALabRemoteUploader).onClose();
    super.onClose();
  }
}
