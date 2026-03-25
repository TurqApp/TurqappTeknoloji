import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';

part 'profile_stats_repository_metrics_part.dart';

class _CachedProfileStats {
  final Map<String, dynamic> data;
  final DateTime cachedAt;

  const _CachedProfileStats({
    required this.data,
    required this.cachedAt,
  });
}

class ProfileStatsRepository extends GetxService {
  static const Duration _ttl = Duration(minutes: 20);
  static const String _prefsPrefix = 'profile_stats_repository_v1';

  SharedPreferences? _prefs;
  final Map<String, _CachedProfileStats> _memory = {};
  final FollowRepository _followRepository = FollowRepository.ensure();

  static ProfileStatsRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ProfileStatsRepository>();
    if (!isRegistered) return null;
    return Get.find<ProfileStatsRepository>();
  }

  static ProfileStatsRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ProfileStatsRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }

  Future<Map<String, dynamic>?> getStats(
    String uid, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    if (uid.isEmpty) return null;
    final key = _cacheKey(uid);

    if (preferCache) {
      final memory = _getFromMemory(key);
      if (memory != null) return memory;
      final disk = await _getFromPrefsEntry(key);
      if (disk != null) {
        _memory[key] = _CachedProfileStats(
          data: Map<String, dynamic>.from(disk.data),
          cachedAt: disk.cachedAt,
        );
        return Map<String, dynamic>.from(disk.data);
      }
    }

    if (cacheOnly) return null;

    return null;
  }

  Future<void> setStats(String uid, Map<String, dynamic> data) async {
    if (uid.isEmpty) return;
    final key = _cacheKey(uid);
    final cachedAt = DateTime.now();
    final cloned = Map<String, dynamic>.from(data);
    _memory[key] = _CachedProfileStats(
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

  Future<_CachedProfileStats?> _getFromPrefsEntry(String key) async {
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
      return _CachedProfileStats(
        data: Map<String, dynamic>.from(data),
        cachedAt: cachedAt,
      );
    } catch (_) {
      return null;
    }
  }

  String _cacheKey(String uid) => 'stats:$uid';

  String _prefsKey(String key) => '$_prefsPrefix:$key';
}
