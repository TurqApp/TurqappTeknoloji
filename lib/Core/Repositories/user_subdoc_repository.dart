import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CachedUserSubdoc {
  final Map<String, dynamic> data;
  final DateTime cachedAt;

  const _CachedUserSubdoc({
    required this.data,
    required this.cachedAt,
  });
}

class UserSubdocRepository extends GetxService {
  static const String _prefsPrefix = 'user_subdoc_repository_v1';
  static const Duration _defaultTtl = Duration(hours: 6);

  SharedPreferences? _prefs;
  final Map<String, _CachedUserSubdoc> _memory = {};

  static UserSubdocRepository ensure() {
    if (Get.isRegistered<UserSubdocRepository>()) {
      return Get.find<UserSubdocRepository>();
    }
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
    final key = _cacheKey(uid, collection, docId);

    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(key, ttl: ttl);
      if (memory != null) return memory;

      final disk = await _getFromPrefs(key, ttl: ttl);
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
  }) async {
    if (uid.isEmpty || collection.isEmpty || docId.isEmpty) return;
    final key = _cacheKey(uid, collection, docId);
    final cachedAt = DateTime.now();
    _memory[key] = _CachedUserSubdoc(
      data: Map<String, dynamic>.from(data),
      cachedAt: cachedAt,
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _prefsKey(key),
      jsonEncode({
        't': cachedAt.millisecondsSinceEpoch,
        'd': data,
      }),
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
  }) async {
    final key = _cacheKey(uid, collection, docId);
    _memory.remove(key);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_prefsKey(key));
  }

  Map<String, dynamic>? _getFromMemory(
    String key, {
    required Duration ttl,
  }) {
    final entry = _memory[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > ttl) return null;
    return Map<String, dynamic>.from(entry.data);
  }

  Future<Map<String, dynamic>?> _getFromPrefs(
    String key, {
    required Duration ttl,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_prefsKey(key));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      final data = (decoded['d'] as Map?)?.cast<String, dynamic>();
      if (ts <= 0 || data == null) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedAt) > ttl) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  String _cacheKey(String uid, String collection, String docId) =>
      '$uid::$collection::$docId';

  String _prefsKey(String key) => '$_prefsPrefix:$key';
}
