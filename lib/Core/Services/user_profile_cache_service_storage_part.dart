part of 'user_profile_cache_service.dart';

extension UserProfileCacheServiceStoragePart on UserProfileCacheService {
  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromPrefs();
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
    while (_memory.length > UserProfileCacheService._maxEntries) {
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
      final raw = _prefs?.getString(UserProfileCacheService._prefsKey);
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
      await _prefs?.setString(
        UserProfileCacheService._prefsKey,
        jsonEncode(map),
      );
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
