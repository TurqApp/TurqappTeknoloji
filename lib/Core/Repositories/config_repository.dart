import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'config_repository_query_part.dart';
part 'config_repository_storage_part.dart';

class _CachedConfigDoc {
  final Map<String, dynamic> data;
  final DateTime cachedAt;

  const _CachedConfigDoc({
    required this.data,
    required this.cachedAt,
  });
}

class ConfigRepository extends GetxService {
  static const Duration _defaultTtl = Duration(minutes: 30);
  static const String _prefsKeyPrefix = 'config_repository_v1';

  static ConfigRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ConfigRepository>();
    if (!isRegistered) return null;
    return Get.find<ConfigRepository>();
  }

  static ConfigRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ConfigRepository(), permanent: true);
  }

  SharedPreferences? _prefs;
  final Map<String, _CachedConfigDoc> _memory = {};

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }

  Future<Map<String, dynamic>?> getAdminConfigDoc(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
    Duration ttl = _defaultTtl,
  }) =>
      _getAdminConfigDocImpl(
        docId,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        ttl: ttl,
      );

  Future<void> putAdminConfigDoc(
    String docId,
    Map<String, dynamic> data,
  ) =>
      _putAdminConfigDocImpl(docId, data);

  Future<void> invalidateAdminConfigDoc(String docId) =>
      _invalidateAdminConfigDocImpl(docId);

  Stream<Map<String, dynamic>> watchAdminConfigDoc(
    String docId, {
    Duration ttl = _defaultTtl,
  }) =>
      _watchAdminConfigDocImpl(
        docId,
        ttl: ttl,
      );

  Future<Map<String, dynamic>?> getLegacyConfigDoc({
    required String collection,
    required String docId,
    bool preferCache = true,
    bool forceRefresh = false,
    Duration ttl = _defaultTtl,
  }) =>
      _getLegacyConfigDocImpl(
        collection: collection,
        docId: docId,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        ttl: ttl,
      );
}
