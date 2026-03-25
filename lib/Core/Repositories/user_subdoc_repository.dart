import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'user_subdoc_repository_models_part.dart';
part 'user_subdoc_repository_cache_part.dart';

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
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }

  Future<Map<String, dynamic>> getDoc(
    String uid, {
    required String collection,
    required String docId,
    bool preferCache = true,
    bool forceRefresh = false,
    Duration ttl = _defaultTtl,
  }) async {
    if (uid.isEmpty || collection.isEmpty || docId.isEmpty) {
      return const <String, dynamic>{};
    }
    final key = _userSubdocCacheKey(uid, collection, docId);

    if (!forceRefresh && preferCache) {
      final memory = _getUserSubdocFromMemory(this, key, ttl: ttl);
      if (memory != null) return memory;

      final disk = await _getUserSubdocFromPrefs(this, key, ttl: ttl);
      if (disk != null) {
        _memory[key] = _CachedUserSubdoc(
          data: Map<String, dynamic>.from(disk),
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(collection)
        .doc(docId)
        .get();
    final data =
        Map<String, dynamic>.from(doc.data() ?? const <String, dynamic>{});
    await putDoc(
      uid,
      collection: collection,
      docId: docId,
      data: data,
    );
    return data;
  }

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
  }) async {
    if (uid.isEmpty || collection.isEmpty || docId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(collection)
        .doc(docId)
        .set(data, SetOptions(merge: merge));
    final current = await getDoc(
      uid,
      collection: collection,
      docId: docId,
      preferCache: true,
      forceRefresh: false,
    );
    final merged = merge
        ? (Map<String, dynamic>.from(current)..addAll(data))
        : Map<String, dynamic>.from(data);
    await putDoc(
      uid,
      collection: collection,
      docId: docId,
      data: merged,
    );
  }

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
