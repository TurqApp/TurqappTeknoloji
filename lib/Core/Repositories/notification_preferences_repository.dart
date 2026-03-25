import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'notification_preferences_repository_models_part.dart';

class NotificationPreferencesRepository extends GetxService {
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'notification_preferences_repository_v1';

  SharedPreferences? _prefs;
  final Map<String, _CachedNotificationPreferences> _memory = {};

  static NotificationPreferencesRepository? maybeFind() {
    final isRegistered = Get.isRegistered<NotificationPreferencesRepository>();
    if (!isRegistered) return null;
    return Get.find<NotificationPreferencesRepository>();
  }

  static NotificationPreferencesRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(NotificationPreferencesRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    _handleNotificationPreferencesInit();
  }

  Future<Map<String, dynamic>?> getPreferences(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    if (uid.isEmpty) return null;
    final key = _cacheKey(uid);

    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(key);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(key);
      if (disk != null) {
        _memory[key] = _CachedNotificationPreferences(
          data: Map<String, dynamic>.from(disk),
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .get();
    final data = Map<String, dynamic>.from(
      doc.data() ?? const <String, dynamic>{},
    );
    await putPreferences(uid, data);
    return data;
  }

  Stream<Map<String, dynamic>> watchPreferences(String uid) async* {
    if (uid.isEmpty) {
      yield const <String, dynamic>{};
      return;
    }

    final cached = await getPreferences(uid, preferCache: true);
    if (cached != null) {
      yield Map<String, dynamic>.from(cached);
    }

    yield* FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .snapshots()
        .asyncMap((snap) async {
      final data = Map<String, dynamic>.from(
        snap.data() ?? const <String, dynamic>{},
      );
      await putPreferences(uid, data);
      return data;
    });
  }

  Future<void> putPreferences(String uid, Map<String, dynamic> data) async {
    if (uid.isEmpty) return;
    final key = _cacheKey(uid);
    final cachedAt = DateTime.now();
    final cloned = Map<String, dynamic>.from(data);
    _memory[key] = _CachedNotificationPreferences(
      data: cloned,
      cachedAt: cachedAt,
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _prefsKey(key),
      jsonEncode({
        't': cachedAt.millisecondsSinceEpoch,
        'd': cloned,
      }),
    );
  }

  Future<void> invalidate(String uid) async {
    if (uid.isEmpty) return;
    final key = _cacheKey(uid);
    _memory.remove(key);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_prefsKey(key));
  }

  Map<String, dynamic>? _getFromMemory(String key) {
    final entry = _memory[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > _ttl) return null;
    return Map<String, dynamic>.from(entry.data);
  }

  Future<Map<String, dynamic>?> _getFromPrefs(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_prefsKey(key));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      final data = (decoded['d'] as Map?)?.cast<String, dynamic>();
      if (ts <= 0 || data == null) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedAt) > _ttl) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  String _cacheKey(String uid) => 'notifications:$uid';

  String _prefsKey(String key) => '$_prefsPrefix:$key';
}
