part of 'qa_lab_remote_uploader.dart';

class QALabRemoteUploader extends _QALabRemoteUploaderBase {
  QALabRemoteUploader({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : super(firestore: firestore, auth: auth);
}
