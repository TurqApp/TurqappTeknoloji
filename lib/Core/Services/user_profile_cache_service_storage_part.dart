part of 'user_profile_cache_service.dart';

extension UserProfileCacheServiceStoragePart on UserProfileCacheService {
  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
      final parsedNum = num.tryParse(value.trim());
      if (parsedNum != null) return parsedNum.toInt();
    }
    return fallback;
  }

  bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return fallback;
  }

  Future<void> _initialize() async {
    _prefs = await ensureLocalPreferenceRepository().sharedPreferences();
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
    return _cloneUserProfileMap(entry.data);
  }

  void _put(String uid, Map<String, dynamic> profile) {
    _memory.remove(uid);
    _memory[uid] = _CachedUserProfile(
      data: _cloneUserProfileMap(profile),
      cachedAt: DateTime.now(),
    );
    _trimIfNeeded();
    _dirty = true;
    _schedulePersist();

    final imageUrl = (profile['avatarUrl'] ?? '').toString();
    if (imageUrl.isNotEmpty && !QALabMode.integrationSmokeRun) {
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
      final prefs = _prefs;
      final raw = prefs?.getString(UserProfileCacheService._prefsKey);
      if (raw == null || raw.trim().isEmpty) return;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        prefs?.remove(UserProfileCacheService._prefsKey);
        return;
      }

      var validEntries = 0;
      var shouldPrune = false;
      for (final entry in json.entries) {
        final value = entry.value;
        if (value is! Map) {
          shouldPrune = true;
          continue;
        }
        final cachedAtMs = _asInt(value['t']);
        final data = (value['d'] as Map?)?.cast<String, dynamic>();
        if (cachedAtMs <= 0 || data == null) {
          shouldPrune = true;
          continue;
        }

        final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
        if (DateTime.now().difference(cachedAt) > _ttl) {
          shouldPrune = true;
          continue;
        }

        _memory[entry.key] = _CachedUserProfile(
          data: _cloneUserProfileMap(data),
          cachedAt: cachedAt,
        );
        validEntries++;
      }
      if (validEntries == 0 && json.isNotEmpty) {
        prefs?.remove(UserProfileCacheService._prefsKey);
        return;
      }
      _trimIfNeeded();
      if (shouldPrune) {
        _dirty = true;
        _schedulePersist();
      }
    } catch (_) {
      _prefs?.remove(UserProfileCacheService._prefsKey);
    }
  }

  Future<void> _persistToPrefs() async {
    try {
      final map = <String, dynamic>{};
      for (final entry in _memory.entries) {
        map[entry.key] = {
          't': entry.value.cachedAt.millisecondsSinceEpoch,
          'd': _cloneUserProfileMap(entry.value.data),
        };
      }
      await _prefs?.setString(
        UserProfileCacheService._prefsKey,
        jsonEncode(map),
      );
    } catch (_) {}
  }

  Map<String, dynamic> _sanitizeProfile(Map<String, dynamic> raw) {
    Map<String, dynamic> asMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        return _cloneUserProfileMap(value);
      }
      if (value is Map) {
        return _cloneUserProfileMap(
          value.map(
            (key, entry) => MapEntry(key.toString(), entry),
          ),
        );
      }
      return const <String, dynamic>{};
    }

    final profile = asMap(raw['profile']);
    final publicProfile = asMap(raw['publicProfile']);
    final scoped = <String, dynamic>{}
      ..addAll(profile)
      ..addAll(publicProfile);

    final username =
        (raw['username'] ?? scoped['username'] ?? '').toString().trim();
    final usernameLower =
        (raw['usernameLower'] ?? scoped['usernameLower'] ?? '')
            .toString()
            .trim();
    final rawNickname =
        (raw['nickname'] ?? scoped['nickname'] ?? '').toString().trim();
    final nickname = _resolveHandle(
      nickname: rawNickname,
      username: username,
      usernameLower: usernameLower,
    );
    final firstName =
        (raw['firstName'] ?? scoped['firstName'] ?? '').toString().trim();
    final lastName =
        (raw['lastName'] ?? scoped['lastName'] ?? '').toString().trim();
    final fullNameParts =
        [firstName, lastName].where((e) => e.isNotEmpty).join(' ');
    final displayName = (raw['displayName'] ?? scoped['displayName'] ?? '')
            .toString()
            .trim()
            .isNotEmpty
        ? (raw['displayName'] ?? scoped['displayName'] ?? '').toString().trim()
        : (fullNameParts.isNotEmpty ? fullNameParts : nickname);
    final avatarUrl = resolveAvatarUrl(raw, profile: scoped);
    final followerCount = raw['counterOfFollowers'] ?? 0;
    final followingCount = raw['counterOfFollowings'] ?? 0;
    final postCount = raw['counterOfPosts'] ?? 0;

    return <String, dynamic>{
      'userID': (raw['userID'] ?? '').toString(),
      'displayName': displayName,
      'nickname': nickname,
      'username': username,
      'usernameLower': usernameLower,
      'avatarUrl': avatarUrl,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': (raw['fullName'] ?? scoped['fullName'] ?? '').toString(),
      'token': (raw['token'] ?? scoped['token'] ?? '').toString(),
      'bio': (raw['bio'] ?? scoped['bio'] ?? '').toString(),
      'meslekKategori':
          (raw['meslekKategori'] ?? scoped['meslekKategori'] ?? '').toString(),
      'rozet': (raw['rozet'] ??
              raw['badge'] ??
              scoped['rozet'] ??
              scoped['badge'] ??
              '')
          .toString(),
      'counterOfFollowers': followerCount,
      'counterOfFollowings': followingCount,
      'counterOfPosts': postCount,
      'isApproved': _asBool(raw['isApproved'] ?? scoped['isApproved']),
      'isPrivate': _asBool(raw['isPrivate'] ?? scoped['isPrivate']),
      'isDeleted': _asBool(raw['isDeleted'] ?? scoped['isDeleted']),
      'accountStatus':
          (raw['accountStatus'] ?? scoped['accountStatus'] ?? '').toString(),
      'singleDeviceSessionEnabled': _asBool(
        raw['singleDeviceSessionEnabled'],
      ),
      'activeSessionDeviceKey':
          (raw['activeSessionDeviceKey'] ?? '').toString(),
      'activeSessionUpdatedAt': _asInt(raw['activeSessionUpdatedAt']),
      'deviceID': (raw['deviceID'] ?? '').toString(),
      'email': (raw['email'] ?? scoped['email'] ?? '').toString(),
      if (profile.isNotEmpty) 'profile': profile,
      if (publicProfile.isNotEmpty) 'publicProfile': publicProfile,
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

  Map<String, dynamic> _cloneUserProfileMap(Map<String, dynamic> source) {
    return source.map(
      (key, value) => MapEntry(key, _cloneUserProfileValue(value)),
    );
  }

  dynamic _cloneUserProfileValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _cloneUserProfileValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_cloneUserProfileValue).toList(growable: false);
    }
    return value;
  }
}
