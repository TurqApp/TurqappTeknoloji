import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'user_subdoc_repository_models_part.dart';
part 'user_subdoc_repository_cache_part.dart';
part 'user_subdoc_repository_runtime_part.dart';

class UserSubdocRepository extends GetxService {
  static const String _prefsPrefix = 'user_subdoc_repository_v1';
  static const Duration _defaultTtl = Duration(hours: 6);

  SharedPreferences? _prefs;
  final Map<String, _CachedUserSubdoc> _memory = {};

  static UserSubdocRepository? maybeFind() {
    final isRegistered = Get.isRegistered<UserSubdocRepository>();
    if (!isRegistered) return null;
    return Get.find<UserSubdocRepository>();
  }

  static UserSubdocRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(UserSubdocRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    _handleUserSubdocRepositoryInit();
  }

  Future<Map<String, dynamic>> getDoc(
    String uid, {
    required String collection,
    required String docId,
    bool preferCache = true,
    bool forceRefresh = false,
    Duration ttl = _defaultTtl,
  }) =>
      _getUserSubdocDoc(
        uid,
        collection: collection,
        docId: docId,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        ttl: ttl,
      );

  Future<void> putDoc(
    String uid, {
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) {
    return _putUserSubdoc(
      this,
      uid,
      collection: collection,
      docId: docId,
      data: data,
    );
  }

  Future<void> setDoc(
    String uid, {
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) =>
      _setUserSubdocDoc(
        uid,
        collection: collection,
        docId: docId,
        data: data,
        merge: merge,
      );

  Future<void> invalidate(
    String uid, {
    required String collection,
    required String docId,
  }) {
    return _invalidateUserSubdoc(
      this,
      uid,
      collection: collection,
      docId: docId,
    );
  }
}
