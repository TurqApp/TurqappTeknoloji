import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Models/current_user_model.dart';

class UserSummary {
  final String userID;
  final String displayName;
  final String nickname;
  final String username;
  final String avatarUrl;
  final String bio;
  final String rozet;
  final String token;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final bool isPrivate;
  final bool isDeleted;
  final bool isApproved;

  const UserSummary({
    required this.userID,
    required this.displayName,
    required this.nickname,
    required this.username,
    required this.avatarUrl,
    required this.bio,
    required this.rozet,
    required this.token,
    required this.followerCount,
    required this.followingCount,
    required this.postCount,
    required this.isPrivate,
    required this.isDeleted,
    required this.isApproved,
  });

  factory UserSummary.fromMap(String uid, Map<String, dynamic> raw) {
    return UserSummary(
      userID: uid,
      displayName: (raw['displayName'] ?? '').toString().trim(),
      nickname: (raw['nickname'] ?? '').toString().trim(),
      username: (raw['username'] ?? '').toString().trim(),
      avatarUrl: (raw['avatarUrl'] ?? '').toString().trim(),
      bio: (raw['bio'] ?? '').toString(),
      rozet: (raw['rozet'] ?? '').toString().trim(),
      token: (raw['token'] ?? '').toString().trim(),
      followerCount: _toInt(raw['followerCount'] ?? raw['followersCount']),
      followingCount: _toInt(raw['followingCount']),
      postCount: _toInt(raw['postCount']),
      isPrivate: raw['isPrivate'] == true,
      isDeleted: raw['isDeleted'] == true,
      isApproved: raw['isApproved'] == true,
    );
  }

  factory UserSummary.fromCurrentUser(CurrentUserModel user) {
    final fullName = [user.firstName.trim(), user.lastName.trim()]
        .where((e) => e.isNotEmpty)
        .join(' ');
    return UserSummary(
      userID: user.userID,
      displayName: fullName.isNotEmpty ? fullName : user.nickname.trim(),
      nickname: user.nickname.trim(),
      username: user.nickname.trim(),
      avatarUrl: user.avatarUrl.trim(),
      bio: user.bio,
      rozet: user.rozet.trim(),
      token: user.token.trim(),
      followerCount: user.counterOfFollowers,
      followingCount: user.counterOfFollowings,
      postCount: user.counterOfPosts,
      isPrivate: user.gizliHesap,
      isDeleted: user.deletedAccount,
      isApproved: user.hesapOnayi,
    );
  }

  String get preferredName {
    if (displayName.trim().isNotEmpty) return displayName.trim();
    if (nickname.trim().isNotEmpty) return nickname.trim();
    return username.trim();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userID': userID,
      'displayName': displayName,
      'nickname': nickname,
      'username': username,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'rozet': rozet,
      'token': token,
      'followerCount': followerCount,
      'followersCount': followerCount,
      'followingCount': followingCount,
      'postCount': postCount,
      'isPrivate': isPrivate,
      'isDeleted': isDeleted,
      'isApproved': isApproved,
    };
  }

  static int _toInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}

class UserRepository extends GetxService {
  final Map<String, _TimedUserLookup<bool>> _existsCache =
      <String, _TimedUserLookup<bool>>{};
  final Map<String, _TimedUserLookup<Map<String, dynamic>?>> _queryCache =
      <String, _TimedUserLookup<Map<String, dynamic>?>>{};

  static UserRepository ensure() {
    if (Get.isRegistered<UserRepository>()) {
      return Get.find<UserRepository>();
    }
    return Get.put(UserRepository(), permanent: true);
  }

  UserProfileCacheService get _cache {
    if (Get.isRegistered<UserProfileCacheService>()) {
      return Get.find<UserProfileCacheService>();
    }
    return Get.put(UserProfileCacheService(), permanent: true);
  }

  Future<UserSummary?> getUser(
    String uid, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    if (uid.isEmpty) return null;
    final data = await _cache.getProfile(
      uid,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    if (data == null) return null;
    return UserSummary.fromMap(uid, data);
  }

  Future<Map<String, dynamic>?> getUserRaw(
    String uid, {
    bool preferCache = true,
    bool cacheOnly = false,
    bool forceServer = false,
  }) async {
    if (uid.isEmpty) return null;
    final data = await _cache.getProfile(
      uid,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
      forceServer: forceServer,
    );
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<void> putUserRaw(String uid, Map<String, dynamic> data) async {
    if (uid.isEmpty || data.isEmpty) return;
    await _cache.putProfile(uid, data);
  }

  Future<void> updateUserFields(
    String uid,
    Map<String, dynamic> data, {
    bool mergeIntoCache = true,
  }) async {
    if (uid.isEmpty || data.isEmpty) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update(data);
    if (!mergeIntoCache) return;
    final existing = _cache.peekProfile(uid, allowStale: true) ??
        const <String, dynamic>{};
    final merged = Map<String, dynamic>.from(existing)..addAll(data);
    await _cache.putProfile(uid, merged);
  }

  Future<void> upsertUserFields(
    String uid,
    Map<String, dynamic> data, {
    bool mergeIntoCache = true,
  }) async {
    if (uid.isEmpty || data.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
    if (!mergeIntoCache) return;
    final existing = _cache.peekProfile(uid, allowStale: true) ??
        const <String, dynamic>{};
    final merged = Map<String, dynamic>.from(existing)..addAll(data);
    await _cache.putProfile(uid, merged);
  }

  UserSummary? peekUser(String uid, {bool allowStale = true}) {
    if (uid.isEmpty) return null;
    final data = _cache.peekProfile(uid, allowStale: allowStale);
    if (data == null) return null;
    return UserSummary.fromMap(uid, data);
  }

  Future<Map<String, UserSummary>> getUsers(
    List<String> uids, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final result = <String, UserSummary>{};
    final data = await _cache.getProfiles(
      uids,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    for (final entry in data.entries) {
      result[entry.key] = UserSummary.fromMap(entry.key, entry.value);
    }
    return result;
  }

  Future<Map<String, Map<String, dynamic>>> getUsersRaw(
    List<String> uids, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final data = await _cache.getProfiles(
      uids,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    return data.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
    );
  }

  Future<void> seedCurrentUser(CurrentUserModel user) async {
    await _cache.putProfile(
        user.userID, UserSummary.fromCurrentUser(user).toMap());
  }

  Future<void> seedUser(UserSummary user) async {
    await _cache.putProfile(user.userID, user.toMap());
  }

  Future<void> invalidateUser(String uid) async {
    await _cache.invalidateUser(uid);
  }

  Future<void> clearAll() async {
    await _cache.clearAll();
    _existsCache.clear();
    _queryCache.clear();
  }

  Future<bool> emailExists(
    String email, {
    bool preferCache = true,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final key = 'email::$normalized';
    final cached = _existsCache[key];
    if (preferCache &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            const Duration(minutes: 10)) {
      return cached.value;
    }
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: normalized)
        .limit(1)
        .get();
    final exists = snap.docs.isNotEmpty;
    _existsCache[key] = _TimedUserLookup<bool>(
      value: exists,
      cachedAt: DateTime.now(),
    );
    return exists;
  }

  Future<bool> usernameLowerAvailable(
    String usernameLower, {
    bool preferCache = true,
  }) async {
    final normalized = usernameLower.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final key = 'usernameLower::$normalized';
    final cached = _existsCache[key];
    if (preferCache &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            const Duration(minutes: 10)) {
      return cached.value;
    }
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('usernameLower', isEqualTo: normalized)
        .limit(1)
        .get();
    final available = snap.docs.isEmpty;
    _existsCache[key] = _TimedUserLookup<bool>(
      value: available,
      cachedAt: DateTime.now(),
    );
    return available;
  }

  Future<Map<String, dynamic>?> findUserByEmail(
    String email, {
    bool preferCache = true,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final key = 'findEmail::$normalized';
    final cached = _queryCache[key];
    if (preferCache &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            const Duration(minutes: 10)) {
      return cached.value == null
          ? null
          : Map<String, dynamic>.from(cached.value!);
    }
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: normalized)
        .limit(1)
        .get();
    Map<String, dynamic>? result;
    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      result = <String, dynamic>{'id': doc.id, ...doc.data()};
      await _cache.putProfile(doc.id, doc.data());
    }
    _queryCache[key] = _TimedUserLookup<Map<String, dynamic>?>(
      value: result == null ? null : Map<String, dynamic>.from(result),
      cachedAt: DateTime.now(),
    );
    return result == null ? null : Map<String, dynamic>.from(result);
  }

  Future<String?> findUserIdByFcmToken(
    String token, {
    bool preferCache = true,
  }) async {
    final normalized = token.trim();
    if (normalized.isEmpty) return null;
    final key = 'findFcmToken::$normalized';
    final cached = _queryCache[key];
    if (preferCache &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            const Duration(minutes: 10)) {
      return cached.value == null ? null : cached.value!['id']?.toString();
    }
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('fcmToken', isEqualTo: normalized)
        .limit(1)
        .get();
    Map<String, dynamic>? result;
    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      result = <String, dynamic>{'id': doc.id, ...doc.data()};
      await _cache.putProfile(doc.id, doc.data());
    }
    _queryCache[key] = _TimedUserLookup<Map<String, dynamic>?>(
      value: result == null ? null : Map<String, dynamic>.from(result),
      cachedAt: DateTime.now(),
    );
    return result == null ? null : result['id']?.toString();
  }

  Future<Map<String, dynamic>?> findUserByNickname(
    String nickname, {
    bool preferCache = true,
  }) async {
    final normalized = nickname.trim();
    if (normalized.isEmpty) return null;
    final key = 'findNickname::$normalized';
    final cached = _queryCache[key];
    if (preferCache &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            const Duration(minutes: 10)) {
      return cached.value == null
          ? null
          : Map<String, dynamic>.from(cached.value!);
    }
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isEqualTo: normalized)
        .limit(1)
        .get();
    Map<String, dynamic>? result;
    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      result = <String, dynamic>{'id': doc.id, ...doc.data()};
      await _cache.putProfile(doc.id, doc.data());
    }
    _queryCache[key] = _TimedUserLookup<Map<String, dynamic>?>(
      value: result == null ? null : Map<String, dynamic>.from(result),
      cachedAt: DateTime.now(),
    );
    return result == null ? null : Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>?> findFirstByNicknamePrefix(
    String prefix, {
    bool preferCache = true,
  }) async {
    final normalized = prefix.trim().toLowerCase();
    if (normalized.length < 2) return null;
    final key = 'nicknamePrefix::$normalized';
    final cached = _queryCache[key];
    if (preferCache &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            const Duration(minutes: 5)) {
      return cached.value == null
          ? null
          : Map<String, dynamic>.from(cached.value!);
    }
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isGreaterThanOrEqualTo: normalized)
        .where('nickname', isLessThan: '$normalized\uf8ff')
        .limit(1)
        .get();
    Map<String, dynamic>? result;
    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      result = <String, dynamic>{'id': doc.id, ...doc.data()};
      await _cache.putProfile(doc.id, doc.data());
    }
    _queryCache[key] = _TimedUserLookup<Map<String, dynamic>?>(
      value: result == null ? null : Map<String, dynamic>.from(result),
      cachedAt: DateTime.now(),
    );
    return result == null ? null : Map<String, dynamic>.from(result);
  }

  Future<List<Map<String, dynamic>>> searchUsersByNicknamePrefix(
    String prefix, {
    int limit = 20,
    bool preferCache = true,
  }) async {
    final normalized = prefix.trim().toLowerCase();
    if (normalized.length < 2) return const <Map<String, dynamic>>[];
    final key = 'nicknamePrefixList::$normalized::$limit';
    final cached = _queryCache[key];
    if (preferCache &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            const Duration(minutes: 5)) {
      final rawList = cached.value?['items'];
      if (rawList is List) {
        return rawList
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false);
      }
      return const <Map<String, dynamic>>[];
    }

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isGreaterThanOrEqualTo: normalized)
        .where('nickname', isLessThan: '$normalized\uf8ff')
        .limit(limit)
        .get();

    final items = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      await _cache.putProfile(doc.id, data);
      items.add(<String, dynamic>{'id': doc.id, ...data});
    }

    _queryCache[key] = _TimedUserLookup<Map<String, dynamic>?>(
      value: <String, dynamic>{
        'items': items,
      },
      cachedAt: DateTime.now(),
    );
    return items
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }

  Stream<Map<String, dynamic>?> watchUserRaw(String uid) {
    if (uid.isEmpty) return const Stream<Map<String, dynamic>?>.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data() ?? const {});
      final sanitized = Map<String, dynamic>.from(_cache.peekProfile(
            uid,
            allowStale: true,
          ) ??
          const <String, dynamic>{})
        ..addAll(data);
      unawaited(_cache.putProfile(uid, sanitized));
      return sanitized;
    });
  }
}

class _TimedUserLookup<T> {
  const _TimedUserLookup({
    required this.value,
    required this.cachedAt,
  });

  final T value;
  final DateTime cachedAt;
}
