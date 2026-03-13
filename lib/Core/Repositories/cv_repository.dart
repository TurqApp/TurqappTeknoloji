import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CachedCv {
  final Map<String, dynamic>? data;
  final DateTime cachedAt;

  const _CachedCv({
    required this.data,
    required this.cachedAt,
  });
}

class CvRepository extends GetxService {
  static const Duration _ttl = Duration(minutes: 30);
  static const String _prefsPrefix = 'cv_repository_v1';

  SharedPreferences? _prefs;
  final Map<String, _CachedCv> _memory = {};

  static CvRepository ensure() {
    if (Get.isRegistered<CvRepository>()) {
      return Get.find<CvRepository>();
    }
    return Get.put(CvRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }

  Future<Map<String, dynamic>?> getCv(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    if (uid.isEmpty) return null;

    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(uid);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(uid);
      if (disk != null) {
        _memory[uid] = _CachedCv(
          data: Map<String, dynamic>.from(disk),
          cachedAt: DateTime.now(),
        );
        return Map<String, dynamic>.from(disk);
      }
    }

    final snap = await FirebaseFirestore.instance.collection('CV').doc(uid).get();
    final data =
        snap.exists && snap.data() != null ? Map<String, dynamic>.from(snap.data()!) : null;
    await setCv(uid, data);
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  Future<void> setCv(String uid, Map<String, dynamic>? data) async {
    if (uid.isEmpty) return;
    final cachedAt = DateTime.now();
    _memory[uid] = _CachedCv(
      data: data == null ? null : Map<String, dynamic>.from(data),
      cachedAt: cachedAt,
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _prefsKey(uid),
      jsonEncode({
        't': cachedAt.millisecondsSinceEpoch,
        'data': data,
      }),
    );
  }

  Future<void> updateCvFields(String uid, Map<String, dynamic> data) async {
    if (uid.isEmpty || data.isEmpty) return;
    await FirebaseFirestore.instance.collection('CV').doc(uid).update(data);
    final current = await getCv(uid, preferCache: true, forceRefresh: false) ??
        <String, dynamic>{};
    final merged = Map<String, dynamic>.from(current)..addAll(data);
    await setCv(uid, merged);
  }

  Future<void> invalidate(String uid) async {
    _memory.remove(uid);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_prefsKey(uid));
  }

  Map<String, dynamic>? _getFromMemory(String uid) {
    final entry = _memory[uid];
    if (entry == null) return null;
    final fresh = DateTime.now().difference(entry.cachedAt) <= _ttl;
    if (!fresh) return null;
    return entry.data == null ? null : Map<String, dynamic>.from(entry.data!);
  }

  Future<Map<String, dynamic>?> _getFromPrefs(String uid) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_prefsKey(uid));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      final fresh = DateTime.now().difference(cachedAt) <= _ttl;
      if (!fresh) return null;
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data);
      }
      if (data is Map) {
        return data.map((key, value) => MapEntry(key.toString(), value));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _prefsKey(String uid) => '$_prefsPrefix:$uid';
}
