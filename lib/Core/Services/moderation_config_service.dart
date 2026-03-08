import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Models/moderation_config_model.dart';

class ModerationConfigService {
  const ModerationConfigService();

  static const String collection = 'adminConfig';
  static const String docId = 'moderation';

  DocumentReference<Map<String, dynamic>> get _docRef =>
      FirebaseFirestore.instance.collection(collection).doc(docId);

  Future<ModerationConfigModel> fetch() async {
    try {
      final snap = await _docRef.get();
      return ModerationConfigModel.fromMap(snap.data());
    } catch (_) {
      return ModerationConfigModel.defaults;
    }
  }

  Stream<ModerationConfigModel> watch() {
    return _docRef.snapshots().map(
          (snap) => ModerationConfigModel.fromMap(snap.data()),
        );
  }
}
