import 'package:cloud_functions/cloud_functions.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Models/moderation_config_model.dart';

class ModerationConfigService {
  const ModerationConfigService();

  static const String collection = 'adminConfig';
  static const String docId = 'moderation';

  Future<ModerationConfigModel> fetch() async {
    try {
      final data = await ensureConfigRepository().getAdminConfigDoc(
        docId,
        preferCache: true,
        ttl: const Duration(hours: 6),
      );
      return ModerationConfigModel.fromMap(data);
    } catch (_) {
      return ModerationConfigModel.defaults;
    }
  }

  Stream<ModerationConfigModel> watch() {
    return ensureConfigRepository()
        .watchAdminConfigDoc(
          docId,
          ttl: const Duration(hours: 6),
        )
        .map(ModerationConfigModel.fromMap);
  }

  Future<ModerationConfigModel> ensureWithCallable() async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('ensureModerationConfig');
      final res = await callable.call();
      final data = res.data;
      if (data is Map && data['config'] is Map) {
        final configMap = Map<String, dynamic>.from(data['config'] as Map);
        await ensureConfigRepository().putAdminConfigDoc(docId, configMap);
        return ModerationConfigModel.fromMap(configMap);
      }
    } catch (_) {
      // ignore and fallback
    }
    return fetch();
  }
}
