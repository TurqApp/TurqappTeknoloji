import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  Future<ModerationConfigModel> ensureWithCallable() async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('ensureModerationConfig');
      final res = await callable.call();
      final data = res.data;
      if (data is Map && data['config'] is Map) {
        final configMap = Map<String, dynamic>.from(data['config'] as Map);
        return ModerationConfigModel.fromMap(configMap);
      }
    } catch (_) {
      // ignore and fallback
    }
    return fetch();
  }
}
