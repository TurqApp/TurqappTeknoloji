part of 'current_user_service.dart';

class CurrentUserCacheStore {
  const CurrentUserCacheStore(this.service);

  final CurrentUserService service;

  Future<bool> loadFromCache({String? expectedUid}) async {
    final resolvedUid = resolveCacheUid(expectedUid);
    try {
      final readDecision = MetadataReadPolicy.currentUserSummary(
        preferCache: true,
        cacheOnly: false,
        forceServer: false,
      );
      if (resolvedUid.isEmpty) {
        return false;
      }

      final cachedJson = _prefs?.getString(cacheKey(resolvedUid));
      final cachedTimestamp = _prefs?.getInt(cacheTimestampKey(resolvedUid));

      if (cachedJson == null || cachedTimestamp == null) {
        return false;
      }

      final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTimestamp;
      if (!readDecision.allowStaleRead &&
          cacheAge > _cacheExpiration.inMilliseconds) {
        return false;
      }
      if (cacheAge > _cacheExpiration.inMilliseconds) {
        return false;
      }

      final json = jsonDecode(cachedJson) as Map<String, dynamic>;
      final cachedUid = (json['userID'] ?? resolvedUid).toString().trim();
      if (cachedUid.isNotEmpty) {
        storeRootUserData(cachedUid, json);
      }
      final user = await service._applyStoredViewSelection(
        CurrentUserModel.fromJson(json),
      );
      if (expectedUid != null &&
          expectedUid.isNotEmpty &&
          user.userID != expectedUid) {
        await clearCache(resolvedUid);
        return false;
      }

      service._currentUser = user;
      service._publishResolvedUser(user);
      unawaited(service._warmAvatar(user));
      return true;
    } catch (_) {
      if (resolvedUid.isNotEmpty) {
        await clearCache(resolvedUid);
      } else {
        await clearActiveCachePointer();
      }
      return false;
    }
  }

  Future<void> saveToCache(CurrentUserModel user) async {
    try {
      final cacheSignature =
          '${user.userID}|${user.nickname}|${user.avatarUrl}|${user.counterOfFollowers}|'
          '${user.counterOfFollowings}|${user.counterOfPosts}|${user.bio}|'
          '${user.gizliHesap}|${user.viewSelection}';
      if (_lastCacheSignature == cacheSignature) {
        return;
      }

      _cacheSaveTimer?.cancel();
      _cacheSaveTimer = Timer(const Duration(milliseconds: 300), () async {
        try {
          final json = jsonEncode(user.toCacheJson());
          await _prefs?.setString(cacheKey(user.userID), json);
          await _prefs?.setInt(
            cacheTimestampKey(user.userID),
            DateTime.now().millisecondsSinceEpoch,
          );
          await _prefs?.setString(
            _activeCacheUidKey,
            user.userID,
          );
          await service._persistViewSelection(user.userID, user.viewSelection);
          _lastCacheSignature = cacheSignature;
        } catch (_) {}
      });
    } catch (_) {}
  }

  Future<void> clearCache([String? uid]) async {
    try {
      final targetUid = resolveCacheUid(uid);
      if (targetUid.isNotEmpty) {
        await _prefs?.remove(cacheKey(targetUid));
        await _prefs?.remove(cacheTimestampKey(targetUid));
      }
      final activeUid = _prefs?.getString(_activeCacheUidKey);
      if (targetUid.isEmpty || activeUid == targetUid) {
        await _prefs?.remove(_activeCacheUidKey);
      }
    } catch (_) {}
  }

  Future<void> clearActiveCachePointer() async {
    try {
      await _prefs?.remove(_activeCacheUidKey);
    } catch (_) {}
  }

  String cacheKey(String uid) => '${_cacheKeyPrefix}_$uid';

  String cacheTimestampKey(String uid) => '${_cacheTimestampKeyPrefix}_$uid';

  String resolveCacheUid(String? uid) {
    final trimmed = uid?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    return (_prefs?.getString(_activeCacheUidKey) ?? '').trim();
  }

  String listCacheKey(String uid, String key) => '$uid::$key';

  bool isFresh(DateTime fetchedAt, Duration ttl) =>
      DateTime.now().difference(fetchedAt) <= ttl;

  void purgeUserScopedCaches(String? uid) {
    if (uid == null || uid.isEmpty) {
      _rootDocCache.clear();
      _subdocCache.clear();
      _listCache.clear();
      return;
    }
    _rootDocCache.removeWhere((key, _) => key == uid);
    _subdocCache.removeWhere((key, _) => key.startsWith('$uid::'));
    _listCache.removeWhere((key, _) => key.startsWith('$uid::'));
    unawaited(_purgeCacheFirstSnapshotSurfaces(userId: uid));
  }

  Future<void> _purgeCacheFirstSnapshotSurfaces({
    String? userId,
  }) async {
    await Future.wait(<Future<void>>[
      maybeFindFeedSnapshotRepository()?.clearUserSnapshots(userId: userId) ??
          Future<void>.value(),
      maybeFindShortSnapshotRepository()?.clearUserSnapshots(userId: userId) ??
          Future<void>.value(),
      ProfilePostsSnapshotRepository.maybeFind()?.clearUserSnapshots(
            userId: userId,
          ) ??
          Future<void>.value(),
    ]);
  }

  void storeRootUserData(String uid, Map<String, dynamic> data) {
    if (uid.isEmpty || data.isEmpty) return;
    _rootDocCache[uid] = _TimedValue<Map<String, dynamic>>(
      value: _cloneCurrentUserDataMap(data),
      fetchedAt: DateTime.now(),
    );
  }

  Map<String, dynamic>? peekRootUserData(
    String uid, {
    bool allowStale = false,
  }) {
    if (uid.isEmpty) return null;
    final cached = _rootDocCache[uid];
    if (cached == null) return null;
    if (!allowStale && !isFresh(cached.fetchedAt, _rootDocCacheTtl)) {
      return null;
    }
    return _cloneCurrentUserDataMap(cached.value);
  }

  Future<Map<String, dynamic>> readRootUserData(
    String uid, {
    bool preferCache = true,
    bool cacheOnly = false,
    bool forceServer = false,
  }) async {
    if (uid.isEmpty) return const <String, dynamic>{};
    final readDecision = MetadataReadPolicy.currentUserSummary(
      preferCache: preferCache,
      cacheOnly: cacheOnly,
      forceServer: forceServer,
    );

    final userRepository = UserRepository.ensure();

    if (!forceServer &&
        readDecision.readOrder.contains(MetadataReadSource.memory)) {
      final memory = peekRootUserData(uid, allowStale: false);
      if (preferCache && memory != null) {
        return memory;
      }
    }

    if (preferCache &&
        !forceServer &&
        readDecision.readOrder.contains(MetadataReadSource.firestoreCache)) {
      final cached = await userRepository.getUserRaw(
        uid,
        preferCache: true,
        cacheOnly: true,
      );
      if (cached != null && cached.isNotEmpty) {
        storeRootUserData(uid, cached);
        return _cloneCurrentUserDataMap(cached);
      }
    }

    if (cacheOnly) {
      return peekRootUserData(
            uid,
            allowStale: readDecision.allowStaleRead,
          ) ??
          const <String, dynamic>{};
    }

    final data = await userRepository.getUserRaw(
          uid,
          preferCache: false,
          cacheOnly: false,
          forceServer: true,
        ) ??
        const <String, dynamic>{};
    if (data.isNotEmpty) {
      storeRootUserData(uid, data);
      await userRepository.putUserRaw(uid, data);
    }
    return _cloneCurrentUserDataMap(data);
  }

  Future<Map<String, dynamic>> readCachedRootUserDataSilently(
    String uid, {
    bool allowStaleMemory = true,
  }) async {
    if (uid.isEmpty) return const <String, dynamic>{};

    final memory = peekRootUserData(
      uid,
      allowStale: allowStaleMemory,
    );
    if (memory != null && memory.isNotEmpty) {
      return memory;
    }

    try {
      final cached = await UserRepository.ensure().getUserRaw(
            uid,
            preferCache: true,
            cacheOnly: true,
          ) ??
          const <String, dynamic>{};
      if (cached.isNotEmpty) {
        storeRootUserData(uid, cached);
        return _cloneCurrentUserDataMap(cached);
      }
    } catch (_) {}

    return peekRootUserData(
          uid,
          allowStale: true,
        ) ??
        const <String, dynamic>{};
  }

  Map<String, dynamic> _cloneCurrentUserDataMap(Map<String, dynamic> source) {
    return source.map(
      (key, value) => MapEntry(key, _cloneCurrentUserDataValue(value)),
    );
  }

  dynamic _cloneCurrentUserDataValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _cloneCurrentUserDataValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_cloneCurrentUserDataValue).toList(growable: false);
    }
    return value;
  }

  void logSilently(String key, Object error, [StackTrace? stackTrace]) {
    final now = DateTime.now();
    final last = _silentLogAt[key];
    if (last != null && now.difference(last) < const Duration(minutes: 1)) {
      return;
    }
    _silentLogAt[key] = now;
    debugPrint('⚠️ [CurrentUserService:$key] $error');
    if (!_suppressCurrentUserSmokeLogs && stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
