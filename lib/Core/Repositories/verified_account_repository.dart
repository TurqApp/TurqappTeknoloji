import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CachedVerifiedAccountStatus {
  final bool exists;
  final DateTime cachedAt;

  const _CachedVerifiedAccountStatus({
    required this.exists,
    required this.cachedAt,
  });
}

class VerifiedAccountRepository extends GetxService {
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'verified_account_repository_v1';

  SharedPreferences? _prefs;
  final Map<String, _CachedVerifiedAccountStatus> _memory = {};

  static VerifiedAccountRepository ensure() {
    if (Get.isRegistered<VerifiedAccountRepository>()) {
      return Get.find<VerifiedAccountRepository>();
    }
    return Get.put(VerifiedAccountRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }

  Future<bool> hasApplication(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    if (uid.isEmpty) return false;
    final key = _cacheKey(uid);
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(key);
      if (memory != null) return memory;

      final disk = await _getFromPrefs(key);
      if (disk != null) {
        _memory[key] = _CachedVerifiedAccountStatus(
          exists: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final doc = await FirebaseFirestore.instance
        .collection('TurqAppVerified')
        .doc(uid)
        .get();
    final exists = doc.exists;
    await _store(uid, exists);
    return exists;
  }

  Future<void> submitApplication(Map<String, dynamic> payload) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('TurqAppVerified')
        .doc(uid)
        .set(payload, SetOptions(merge: true));
    await _store(uid, true);
  }

  Future<void> _store(String uid, bool exists) async {
    final key = _cacheKey(uid);
    final cachedAt = DateTime.now();
    _memory[key] = _CachedVerifiedAccountStatus(
      exists: exists,
      cachedAt: cachedAt,
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _prefsKey(key),
      jsonEncode({
        't': cachedAt.millisecondsSinceEpoch,
        'e': exists,
      }),
    );
  }

  bool? _getFromMemory(String key) {
    final entry = _memory[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > _ttl) return null;
    return entry.exists;
  }

  Future<bool?> _getFromPrefs(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_prefsKey(key));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedAt) > _ttl) return null;
      return decoded['e'] == true;
    } catch (_) {
      return null;
    }
  }

  String _cacheKey(String uid) => 'verified::$uid';

  String _prefsKey(String key) => '$_prefsPrefix:$key';
}
