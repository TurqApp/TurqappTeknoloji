import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static FollowRepository ensure() {
    if (Get.isRegistered<FollowRepository>()) {
      return Get.find<FollowRepository>();
    }
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

  Future<Set<String>> getFollowingIds(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    return getRelationIds(
      uid,
      relation: 'followings',
      preferCache: preferCache,
      forceRefresh: forceRefresh,
    );
  }

  Future<Set<String>> getFollowerIds(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    return getRelationIds(
      uid,
      relation: 'followers',
      preferCache: preferCache,
      forceRefresh: forceRefresh,
    );
  }

  Future<Set<String>> getRelationIds(
    String uid, {
    required String relation,
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    if (uid.isEmpty) return <String>{};
    final relationKey = _relationKey(uid, relation);

    if (!forceRefresh) {
      final memory = _getRelationFromMemory(relationKey, allowStale: false);
      if (preferCache && memory != null) {
        return memory;
      }

      final disk = await _getRelationFromPrefs(relationKey, allowStale: false);
      if (preferCache && disk != null) {
        _relationMemory[relationKey] =
            _CachedFollowingSet(ids: disk, cachedAt: DateTime.now());
        return disk;
      }
    }

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(relation)
        .get();
    final ids = snap.docs.map((doc) => doc.id).toSet();
    await _persistRelation(relationKey, ids);
    return ids;
  }

  Future<bool> isFollowing(
    String otherUid, {
    String? currentUid,
    bool preferCache = true,
  }) async {
    final me = currentUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    if (me.isEmpty || otherUid.isEmpty) return false;

    final cached = await getFollowingIds(
      me,
      preferCache: preferCache,
      forceRefresh: false,
    );
    if (cached.contains(otherUid)) return true;

    if (preferCache && _hasFreshCache(me)) {
      return false;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(me)
        .collection('followings')
        .doc(otherUid)
        .get();
    if (!doc.exists) return false;
    await applyToggle(
      me,
      otherUid,
      nowFollowing: true,
    );
    return true;
  }

  Future<void> applyToggle(
    String currentUid,
    String otherUid, {
    required bool nowFollowing,
  }) async {
    if (currentUid.isEmpty || otherUid.isEmpty) return;
    final current = await getFollowingIds(
      currentUid,
      preferCache: true,
      forceRefresh: false,
    );
    final next = current.toSet();
    if (nowFollowing) {
      next.add(otherUid);
    } else {
      next.remove(otherUid);
    }
    await _persistRelation(_relationKey(currentUid, 'followings'), next);
  }

  Future<void> invalidate(String uid) async {
    if (uid.isEmpty) return;
    _memory.remove(uid);
    _relationMemory.remove(_relationKey(uid, 'followings'));
    _relationMemory.remove(_relationKey(uid, 'followers'));
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_prefsKey(uid));
    await _prefs?.remove(_relationPrefsKey(_relationKey(uid, 'followings')));
    await _prefs?.remove(_relationPrefsKey(_relationKey(uid, 'followers')));
  }

  Future<void> clearAll() async {
    final keys = _memory.keys.toList();
    _memory.clear();
    final relationKeys = _relationMemory.keys.toList();
    _relationMemory.clear();
    _prefs ??= await SharedPreferences.getInstance();
    for (final uid in keys) {
      await _prefs?.remove(_prefsKey(uid));
    }
    for (final relationKey in relationKeys) {
      await _prefs?.remove(_relationPrefsKey(relationKey));
    }
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
      final uid = relationKey.substring(0, relationKey.length - ':followings'.length);
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
      final uid = relationKey.substring(0, relationKey.length - ':followings'.length);
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
