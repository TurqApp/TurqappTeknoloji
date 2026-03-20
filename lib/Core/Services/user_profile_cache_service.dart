import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_cache_policy.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_read_policy.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';

import 'turq_image_cache_manager.dart';

class UserProfileCacheService extends GetxService {
  static const String _prefsKey = 'user_profile_cache_v2';
  static const int _maxEntries = 2000;
  Duration get _ttl =>
      MetadataCachePolicy.ttlFor(MetadataCacheBucket.userProfileSummary);

  final LinkedHashMap<String, _CachedUserProfile> _memory =
      LinkedHashMap<String, _CachedUserProfile>();

  SharedPreferences? _prefs;
  Timer? _persistTimer;
  bool _dirty = false;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromPrefs();
  }

  Future<Map<String, dynamic>?> getProfile(
    String uid, {
    bool preferCache = true,
    bool cacheOnly = false,
    bool forceServer = false,
  }) async {
    if (uid.isEmpty) return null;
    final readDecision = MetadataReadPolicy.userProfileSummary(
      preferCache: preferCache,
      cacheOnly: cacheOnly,
      forceServer: forceServer,
    );

    if (!forceServer && preferCache) {
      final cached = _getFromMemory(
        uid,
        allowStale: readDecision.allowStaleRead,
      );
      if (cached != null) return cached;
    }

    if (cacheOnly) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.cache));
      if (!doc.exists) {
        return _getFromMemory(
          uid,
          allowStale: readDecision.allowStaleRead,
        );
      }
      final map = _sanitizeProfile(doc.data() ?? const <String, dynamic>{});
      _put(uid, map);
      return map;
    }

    if (!forceServer && preferCache) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
        if (doc.exists) {
          final map = _sanitizeProfile(doc.data() ?? const <String, dynamic>{});
          _put(uid, map);
          return map;
        }
      } catch (_) {}
    }

    final server =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!server.exists) {
      return _getFromMemory(
        uid,
        allowStale: readDecision.allowStaleRead,
      );
    }
    final map = _sanitizeProfile(server.data() ?? const <String, dynamic>{});
    _put(uid, map);
    return map;
  }

  Future<void> putProfile(String uid, Map<String, dynamic> profile) async {
    if (uid.isEmpty) return;
    _put(uid, _sanitizeProfile(profile));
  }

  Map<String, dynamic>? peekProfile(
    String uid, {
    bool allowStale = true,
  }) {
    if (uid.isEmpty) return null;
    return _getFromMemory(uid, allowStale: allowStale);
  }

  Future<void> invalidateUser(String uid) async {
    if (uid.isEmpty) return;
    if (_memory.remove(uid) != null) {
      _dirty = true;
      _schedulePersist();
    }
  }

  Future<void> clearAll() async {
    if (_memory.isEmpty) return;
    _memory.clear();
    _dirty = true;
    await _persistToPrefs();
  }

  Future<Map<String, Map<String, dynamic>>> getProfiles(
    List<String> uids, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final out = <String, Map<String, dynamic>>{};
    final unique = uids.where((e) => e.isNotEmpty).toSet().toList();
    if (unique.isEmpty) return out;

    final missing = <String>[];
    for (final uid in unique) {
      if (preferCache) {
        final cached = _getFromMemory(uid, allowStale: true);
        if (cached != null) {
          out[uid] = cached;
          continue;
        }
      }
      missing.add(uid);
    }

    if (missing.isEmpty) return out;

    final fetched = await _fetchUsersChunked(
      missing,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    out.addAll(fetched);
    return out;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchUsersChunked(
    List<String> uids, {
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final result = <String, Map<String, dynamic>>{};
    const int chunkSize = 10;

    for (int i = 0; i < uids.length; i += chunkSize) {
      final chunk = uids.sublist(i, (i + chunkSize).clamp(0, uids.length));
      if (chunk.isEmpty) continue;

      if (preferCache) {
        try {
          final cacheSnap = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get(const GetOptions(source: Source.cache));
          for (final doc in cacheSnap.docs) {
            final map = _sanitizeProfile(doc.data());
            _put(doc.id, map);
            result[doc.id] = map;
          }
        } catch (_) {}
      }

      final unresolved =
          chunk.where((uid) => !result.containsKey(uid)).toList();
      if (unresolved.isEmpty || cacheOnly) continue;

      try {
        final serverSnap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: unresolved)
            .get();
        for (final doc in serverSnap.docs) {
          final map = _sanitizeProfile(doc.data());
          _put(doc.id, map);
          result[doc.id] = map;
        }
      } catch (_) {}
    }

    return result;
  }

  Map<String, dynamic>? _getFromMemory(
    String uid, {
    bool allowStale = false,
  }) {
    final entry = _memory[uid];
    if (entry == null) return null;

    final isFresh = DateTime.now().difference(entry.cachedAt) <= _ttl;
    if (!isFresh && !allowStale) {
      _memory.remove(uid);
      _dirty = true;
      _schedulePersist();
      return null;
    }

    _memory.remove(uid);
    _memory[uid] = entry;
    return Map<String, dynamic>.from(entry.data);
  }

  void _put(String uid, Map<String, dynamic> profile) {
    _memory.remove(uid);
    _memory[uid] = _CachedUserProfile(
      data: Map<String, dynamic>.from(profile),
      cachedAt: DateTime.now(),
    );
    _trimIfNeeded();
    _dirty = true;
    _schedulePersist();

    final imageUrl = (profile['avatarUrl'] ?? '').toString();
    if (imageUrl.isNotEmpty) {
      unawaited(TurqImageCacheManager.instance.getSingleFile(imageUrl));
    }
  }

  void _trimIfNeeded() {
    while (_memory.length > _maxEntries) {
      _memory.remove(_memory.keys.first);
    }
  }

  void _schedulePersist() {
    _persistTimer ??= Timer(const Duration(seconds: 2), () {
      _persistTimer = null;
      if (_dirty) {
        _dirty = false;
        _persistToPrefs();
      }
    });
  }

  void _loadFromPrefs() {
    try {
      final raw = _prefs?.getString(_prefsKey);
      if (raw == null || raw.trim().isEmpty) return;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return;

      for (final entry in json.entries) {
        final value = entry.value;
        if (value is! Map) continue;
        final cachedAtMs = (value['t'] as num?)?.toInt() ?? 0;
        final data = (value['d'] as Map?)?.cast<String, dynamic>();
        if (cachedAtMs <= 0 || data == null) continue;

        final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
        if (DateTime.now().difference(cachedAt) > _ttl) continue;

        _memory[entry.key] = _CachedUserProfile(
          data: data,
          cachedAt: cachedAt,
        );
      }
      _trimIfNeeded();
    } catch (_) {}
  }

  Future<void> _persistToPrefs() async {
    try {
      final map = <String, dynamic>{};
      for (final entry in _memory.entries) {
        map[entry.key] = {
          't': entry.value.cachedAt.millisecondsSinceEpoch,
          'd': entry.value.data,
        };
      }
      await _prefs?.setString(_prefsKey, jsonEncode(map));
    } catch (_) {}
  }

  Map<String, dynamic> _sanitizeProfile(Map<String, dynamic> raw) {
    final username = (raw['username'] ?? '').toString().trim();
    final usernameLower = (raw['usernameLower'] ?? '').toString().trim();
    final rawNickname = (raw['nickname'] ?? '').toString().trim();
    final nickname = _resolveHandle(
      nickname: rawNickname,
      username: username,
      usernameLower: usernameLower,
    );
    final firstName = (raw['firstName'] ?? '').toString().trim();
    final lastName = (raw['lastName'] ?? '').toString().trim();
    final fullNameParts =
        [firstName, lastName].where((e) => e.isNotEmpty).join(' ');
    final displayName = (raw['displayName'] ?? '').toString().trim().isNotEmpty
        ? (raw['displayName'] ?? '').toString().trim()
        : (fullNameParts.isNotEmpty ? fullNameParts : nickname);
    final avatarUrl = resolveAvatarUrl(raw);
    final followerCount = raw['followerCount'] ??
        raw['counterOfFollowers'] ??
        raw['followersCount'] ??
        raw['takipci'] ??
        0;
    final followingCount = raw['followingCount'] ??
        raw['counterOfFollowings'] ??
        raw['takip'] ??
        0;
    final postCount =
        raw['postCount'] ?? raw['counterOfPosts'] ?? raw['gonderi'] ?? 0;

    return <String, dynamic>{
      'userID': (raw['userID'] ?? '').toString(),
      'displayName': displayName,
      'nickname': nickname,
      'username': username,
      'usernameLower': usernameLower,
      'avatarUrl': avatarUrl,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': (raw['fullName'] ?? '').toString(),
      'token': (raw['token'] ?? '').toString(),
      'bio': (raw['bio'] ?? '').toString(),
      'rozet': (raw['rozet'] ?? raw['badge'] ?? '').toString(),
      'followerCount': followerCount,
      'followersCount': followerCount,
      'followingCount': followingCount,
      'postCount': postCount,
      'isApproved': raw['isApproved'] == true,
      'isPrivate': raw['isPrivate'] == true,
      'isDeleted': raw['isDeleted'] == true,
      'accountStatus': (raw['accountStatus'] ?? '').toString(),
      'singleDeviceSessionEnabled': raw['singleDeviceSessionEnabled'] == true,
      'activeSessionDeviceKey':
          (raw['activeSessionDeviceKey'] ?? '').toString(),
      'activeSessionUpdatedAt': raw['activeSessionUpdatedAt'] ?? 0,
      'deviceID': (raw['deviceID'] ?? '').toString(),
      'email': (raw['email'] ?? '').toString(),
    };
  }

  String _resolveHandle({
    required String nickname,
    required String username,
    required String usernameLower,
  }) {
    final n = nickname.trim();
    final u = username.trim();
    final ul = usernameLower.trim();

    final hasSpace = hasNicknameWhitespace(n);
    if (n.isNotEmpty && !hasSpace) return n;
    if (u.isNotEmpty) return u;
    if (ul.isNotEmpty) return ul;
    return n;
  }
}

class _CachedUserProfile {
  final Map<String, dynamic> data;
  final DateTime cachedAt;

  _CachedUserProfile({
    required this.data,
    required this.cachedAt,
  });
}
