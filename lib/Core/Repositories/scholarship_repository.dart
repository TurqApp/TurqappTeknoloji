import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/scholarship_firestore_path.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';

part 'scholarship_repository_query_part.dart';
part 'scholarship_repository_action_part.dart';
part 'scholarship_repository_cache_part.dart';
part 'scholarship_repository_fields_part.dart';
part 'scholarship_repository_models_part.dart';

class ScholarshipRepository extends GetxService {
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'scholarship_repository_v1:';
  static const String _applyPrefix = 'scholarship_apply_repository_v1:';
  static const String _countKey = 'scholarship_total_count_v1';
  final _state = _ScholarshipRepositoryState();

  static ScholarshipRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ScholarshipRepository>();
    if (!isRegistered) return null;
    return Get.find<ScholarshipRepository>();
  }

  static ScholarshipRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ScholarshipRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Map<String, dynamic>? _readMemory(String docId) =>
      _ScholarshipRepositoryCacheX(this)._readMemory(docId);

  Future<Map<String, dynamic>?> _readPrefs(String docId) =>
      _ScholarshipRepositoryCacheX(this)._readPrefs(docId);

  Future<void> _store(String docId, Map<String, dynamic> data) =>
      _ScholarshipRepositoryCacheX(this)._store(docId, data);

  List<Map<String, dynamic>>? _readQueryMemory(String key) =>
      _ScholarshipRepositoryCacheX(this)._readQueryMemory(key);

  Future<List<Map<String, dynamic>>?> _readQueryPrefs(String key) =>
      _ScholarshipRepositoryCacheX(this)._readQueryPrefs(key);

  Future<void> _storeQueryDocs(
    String key,
    List<Map<String, dynamic>> items,
  ) =>
      _ScholarshipRepositoryCacheX(this)._storeQueryDocs(key, items);

  Future<void> _invalidateQueryPrefix(String prefix) =>
      _ScholarshipRepositoryCacheX(this)._invalidateQueryPrefix(prefix);

  bool? _readApplyMemory(String key) =>
      _ScholarshipRepositoryCacheX(this)._readApplyMemory(key);

  Future<bool?> _readApplyPrefs(String key) =>
      _ScholarshipRepositoryCacheX(this)._readApplyPrefs(key);

  Future<void> _storeApply(String key, bool value) =>
      _ScholarshipRepositoryCacheX(this)._storeApply(key, value);

  Future<void> _storeRawDoc(String cacheKey, Map<String, dynamic> data) =>
      _ScholarshipRepositoryCacheX(this)._storeRawDoc(cacheKey, data);

  Future<Map<String, dynamic>?> _getRawDoc(String cacheKey) =>
      _ScholarshipRepositoryCacheX(this)._getRawDoc(cacheKey);
}
