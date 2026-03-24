import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'follow_repository_query_part.dart';
part 'follow_repository_action_part.dart';

class _CachedFollowingSet {
  final Set<String> ids;
  final DateTime cachedAt;

  const _CachedFollowingSet({
    required this.ids,
    required this.cachedAt,
  });
}

class FollowRepository extends GetxService {
  static const Duration _ttl = Duration(minutes: 15);
  static const String _prefsKeyPrefix = 'follow_repository_v1';
  static const String _relationPrefsKeyPrefix = 'follow_relation_repository_v1';

  static FollowRepository? maybeFind() {
    final isRegistered = Get.isRegistered<FollowRepository>();
    if (!isRegistered) return null;
    return Get.find<FollowRepository>();
  }

  static FollowRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(FollowRepository(), permanent: true);
  }

  SharedPreferences? _prefs;
  final Map<String, _CachedFollowingSet> _memory = {};
  final Map<String, _CachedFollowingSet> _relationMemory = {};

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }

  bool _hasFreshCache(String uid) {
    final entry = _memory[uid];
    if (entry == null) return false;
    return DateTime.now().difference(entry.cachedAt) <= _ttl;
  }

  String _prefsKey(String uid) => '$_prefsKeyPrefix:$uid';

  String _relationKey(String uid, String relation) => '$uid:$relation';

  Set<String>? _getRelationFromMemory(
    String relationKey, {
    required bool allowStale,
  }) {
    final entry = _relationMemory[relationKey];
    if (entry == null) return null;
    final fresh = DateTime.now().difference(entry.cachedAt) <= _ttl;
    if (!fresh && !allowStale) return null;
    return entry.ids.toSet();
  }

  Future<Set<String>?> _getRelationFromPrefs(
    String relationKey, {
    required bool allowStale,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_relationPrefsKey(relationKey));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      final list =
          (decoded['ids'] as List?)?.cast<String>() ?? const <String>[];
      if (ts <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      final fresh = DateTime.now().difference(cachedAt) <= _ttl;
      if (!fresh && !allowStale) return null;
      return list.toSet();
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistRelation(String relationKey, Set<String> ids) async {
    final cachedAt = DateTime.now();
    _relationMemory[relationKey] =
        _CachedFollowingSet(ids: ids.toSet(), cachedAt: cachedAt);
    if (relationKey.endsWith(':followings')) {
      final uid =
          relationKey.substring(0, relationKey.length - ':followings'.length);
      _memory[uid] = _CachedFollowingSet(ids: ids.toSet(), cachedAt: cachedAt);
    }
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _relationPrefsKey(relationKey),
      jsonEncode({
        't': cachedAt.millisecondsSinceEpoch,
        'ids': ids.toList(),
      }),
    );
    if (relationKey.endsWith(':followings')) {
      final uid =
          relationKey.substring(0, relationKey.length - ':followings'.length);
      await _prefs?.setString(
        _prefsKey(uid),
        jsonEncode({
          't': cachedAt.millisecondsSinceEpoch,
          'ids': ids.toList(),
        }),
      );
    }
  }

  String _relationPrefsKey(String relationKey) =>
      '$_relationPrefsKeyPrefix:$relationKey';
}

class FollowWriteResult {
  final bool nowFollowing;
  final bool limitReached;

  const FollowWriteResult({
    required this.nowFollowing,
    required this.limitReached,
  });
}
