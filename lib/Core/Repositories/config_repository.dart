import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static ConfigRepository ensure() {
    if (Get.isRegistered<ConfigRepository>()) {
      return Get.find<ConfigRepository>();
    }
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
  }) async {
    if (docId.isEmpty) return null;
    final key = _docKey(docId);

    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(key, ttl: ttl);
      if (memory != null) return memory;

      final disk = await _getFromPrefs(key, ttl: ttl);
      if (disk != null) {
        _memory[key] = _CachedConfigDoc(
          data: Map<String, dynamic>.from(disk),
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final doc = await FirebaseFirestore.instance
        .collection('adminConfig')
        .doc(docId)
        .get();
    if (!doc.exists) return null;
    final data =
        Map<String, dynamic>.from(doc.data() ?? const <String, dynamic>{});
    await putAdminConfigDoc(docId, data);
    return data;
  }

  Future<void> putAdminConfigDoc(
    String docId,
    Map<String, dynamic> data,
  ) async {
    if (docId.isEmpty) return;
    final key = _docKey(docId);
    final cachedAt = DateTime.now();
    _memory[key] = _CachedConfigDoc(
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

  Future<void> invalidateAdminConfigDoc(String docId) async {
    final key = _docKey(docId);
    _memory.remove(key);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_prefsKey(key));
  }

  Stream<Map<String, dynamic>> watchAdminConfigDoc(
    String docId, {
    Duration ttl = _defaultTtl,
  }) async* {
    if (docId.isEmpty) {
      yield const <String, dynamic>{};
      return;
    }

    final cached = await getAdminConfigDoc(
      docId,
      preferCache: true,
      forceRefresh: false,
      ttl: ttl,
    );
    if (cached != null) {
      yield Map<String, dynamic>.from(cached);
    }

    yield* FirebaseFirestore.instance
        .collection('adminConfig')
        .doc(docId)
        .snapshots()
        .asyncMap((doc) async {
      final data = Map<String, dynamic>.from(
        doc.data() ?? const <String, dynamic>{},
      );
      if (data.isNotEmpty) {
        await putAdminConfigDoc(docId, data);
      }
      return data;
    });
  }

  Future<Map<String, dynamic>?> getLegacyConfigDoc({
    required String collection,
    required String docId,
    bool preferCache = true,
    bool forceRefresh = false,
    Duration ttl = _defaultTtl,
  }) async {
    if (collection.isEmpty || docId.isEmpty) return null;
    final key = _legacyDocKey(collection, docId);

    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(key, ttl: ttl);
      if (memory != null) return memory;

      final disk = await _getFromPrefs(key, ttl: ttl);
      if (disk != null) {
        _memory[key] = _CachedConfigDoc(
          data: Map<String, dynamic>.from(disk),
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final doc = await FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .get();
    if (!doc.exists) return null;
    final data =
        Map<String, dynamic>.from(doc.data() ?? const <String, dynamic>{});
    await _putLegacyConfigDoc(collection: collection, docId: docId, data: data);
    return data;
  }

  Future<void> _putLegacyConfigDoc({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final key = _legacyDocKey(collection, docId);
    final cachedAt = DateTime.now();
    _memory[key] = _CachedConfigDoc(
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

  Map<String, dynamic>? _getFromMemory(
    String key, {
    required Duration ttl,
  }) {
    final entry = _memory[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > ttl) {
      return null;
    }
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

  String _docKey(String docId) => 'adminConfig:$docId';
  String _legacyDocKey(String collection, String docId) =>
      'legacy:$collection:$docId';

  String _prefsKey(String key) => '$_prefsKeyPrefix:$key';
}
