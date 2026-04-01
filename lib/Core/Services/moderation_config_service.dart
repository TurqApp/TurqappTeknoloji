import 'package:cloud_functions/cloud_functions.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Models/moderation_config_model.dart';

class ModerationConfigService {
  const ModerationConfigService();

  static const String collection = 'adminConfig';
  static const String docId = 'moderation';

  static dynamic _cloneValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _cloneValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_cloneValue).toList(growable: false);
    }
    return value;
  }

  static Map<String, dynamic> _cloneConfigMap(Map source) {
    return source.map(
      (key, value) => MapEntry(key.toString(), _cloneValue(value)),
    );
  }

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
        final configMap = _cloneConfigMap(data['config'] as Map);
        await ensureConfigRepository().putAdminConfigDoc(docId, configMap);
        return ModerationConfigModel.fromMap(configMap);
      }
    } catch (_) {
      // ignore and fallback
    }
    return fetch();
  }
}
