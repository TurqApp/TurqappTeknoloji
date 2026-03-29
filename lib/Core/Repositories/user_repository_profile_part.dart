part of 'user_repository.dart';

extension UserRepositoryProfilePart on UserRepository {
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
    return _cloneUserProfileRawMap(data);
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
    final existing =
        _cache.peekProfile(uid, allowStale: true) ?? const <String, dynamic>{};
    final merged = _cloneUserProfileRawMap(existing)
      ..addAll(_cloneUserProfileRawMap(data));
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
    final existing =
        _cache.peekProfile(uid, allowStale: true) ?? const <String, dynamic>{};
    final merged = _cloneUserProfileRawMap(existing)
      ..addAll(_cloneUserProfileRawMap(data));
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
      (key, value) => MapEntry(key, _cloneUserProfileRawMap(value)),
    );
  }

  Future<void> seedCurrentUser(CurrentUserModel user) async {
    await _cache.putProfile(
      user.userID,
      UserSummary.fromCurrentUser(user).toMap(),
    );
  }

  Future<void> seedUser(UserSummary user) async {
    await _cache.putProfile(user.userID, user.toMap());
  }

  Future<void> invalidateUser(String uid) async {
    await _cache.invalidateUser(uid);
    _existsCache.clear();
    _queryCache.clear();
  }

  Future<void> clearAll() async {
    await _cache.clearAll();
    _existsCache.clear();
    _queryCache.clear();
  }

  Map<String, dynamic> _cloneUserProfileRawMap(Map<String, dynamic> source) {
    return source.map(
      (key, value) => MapEntry(key, _cloneUserProfileRawValue(value)),
    );
  }

  dynamic _cloneUserProfileRawValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _cloneUserProfileRawValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_cloneUserProfileRawValue).toList(growable: false);
    }
    return value;
  }
}
