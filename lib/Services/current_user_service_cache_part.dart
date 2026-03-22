part of 'current_user_service.dart';

const bool _suppressCurrentUserSmokeLogs =
    bool.fromEnvironment('RUN_INTEGRATION_SMOKE', defaultValue: false);

extension CurrentUserServiceCachePart on CurrentUserService {
  Future<bool> _loadFromCache({String? expectedUid}) async {
    try {
      final readDecision = MetadataReadPolicy.currentUserSummary(
        preferCache: true,
        cacheOnly: false,
        forceServer: false,
      );
      final resolvedUid = _resolveCacheUid(expectedUid);
      if (resolvedUid.isEmpty) {
        return false;
      }

      final cachedJson = _prefs?.getString(_cacheKey(resolvedUid));
      final cachedTimestamp = _prefs?.getInt(_cacheTimestampKey(resolvedUid));

      if (cachedJson == null || cachedTimestamp == null) {
        return false;
      }

      final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTimestamp;
      if (!readDecision.allowStaleRead &&
          cacheAge > CurrentUserService._cacheExpiration.inMilliseconds) {
        return false;
      }
      if (cacheAge > CurrentUserService._cacheExpiration.inMilliseconds) {
        return false;
      }

      final json = jsonDecode(cachedJson) as Map<String, dynamic>;
      final cachedUid = (json['userID'] ?? resolvedUid).toString().trim();
      if (cachedUid.isNotEmpty) {
        _storeRootUserData(cachedUid, json);
      }
      final user = await _applyStoredViewSelection(
        CurrentUserModel.fromJson(json),
      );
      if (expectedUid != null &&
          expectedUid.isNotEmpty &&
          user.userID != expectedUid) {
        await _clearCache(resolvedUid);
        return false;
      }

      _currentUser = user;
      _publishResolvedUser(user);
      unawaited(_warmAvatar(user));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveToCache(CurrentUserModel user) async {
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
          await _prefs?.setString(_cacheKey(user.userID), json);
          await _prefs?.setInt(
            _cacheTimestampKey(user.userID),
            DateTime.now().millisecondsSinceEpoch,
          );
          await _prefs?.setString(
            CurrentUserService._activeCacheUidKey,
            user.userID,
          );
          await _persistViewSelection(user.userID, user.viewSelection);
          _lastCacheSignature = cacheSignature;
        } catch (_) {}
      });
    } catch (_) {}
  }

  Future<void> _clearCache([String? uid]) async {
    try {
      final targetUid = _resolveCacheUid(uid);
      if (targetUid.isNotEmpty) {
        await _prefs?.remove(_cacheKey(targetUid));
        await _prefs?.remove(_cacheTimestampKey(targetUid));
      }
      final activeUid = _prefs?.getString(CurrentUserService._activeCacheUidKey);
      if (targetUid.isEmpty || activeUid == targetUid) {
        await _prefs?.remove(CurrentUserService._activeCacheUidKey);
      }
    } catch (_) {}
  }

  String _cacheKey(String uid) => '${CurrentUserService._cacheKeyPrefix}_$uid';

  String _cacheTimestampKey(String uid) =>
      '${CurrentUserService._cacheTimestampKeyPrefix}_$uid';

  String _resolveCacheUid(String? uid) {
    final trimmed = uid?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    return (_prefs?.getString(CurrentUserService._activeCacheUidKey) ?? '')
        .trim();
  }

  String _listCacheKey(String uid, String key) => '$uid::$key';

  bool _isFresh(DateTime fetchedAt, Duration ttl) =>
      DateTime.now().difference(fetchedAt) <= ttl;

  void _purgeUserScopedCaches(String? uid) {
    if (uid == null || uid.isEmpty) {
      _rootDocCache.clear();
      _subdocCache.clear();
      _listCache.clear();
      return;
    }
    _rootDocCache.removeWhere((key, _) => key == uid);
    _subdocCache.removeWhere((key, _) => key.startsWith('$uid::'));
    _listCache.removeWhere((key, _) => key.startsWith('$uid::'));
  }

  void _storeRootUserData(String uid, Map<String, dynamic> data) {
    if (uid.isEmpty || data.isEmpty) return;
    _rootDocCache[uid] = _TimedValue<Map<String, dynamic>>(
      value: Map<String, dynamic>.from(data),
      fetchedAt: DateTime.now(),
    );
  }

  Map<String, dynamic>? _peekRootUserData(
    String uid, {
    bool allowStale = false,
  }) {
    if (uid.isEmpty) return null;
    final cached = _rootDocCache[uid];
    if (cached == null) return null;
    if (!allowStale &&
        !_isFresh(cached.fetchedAt, CurrentUserService._rootDocCacheTtl)) {
      return null;
    }
    return Map<String, dynamic>.from(cached.value);
  }

  Future<Map<String, dynamic>> _readRootUserData(
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
      final memory = _peekRootUserData(uid, allowStale: false);
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
        _storeRootUserData(uid, cached);
        return Map<String, dynamic>.from(cached);
      }
    }

    if (cacheOnly) {
      return _peekRootUserData(
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
      _storeRootUserData(uid, data);
      await userRepository.putUserRaw(uid, data);
    }
    return Map<String, dynamic>.from(data);
  }

  void _logSilently(String key, Object error, [StackTrace? stackTrace]) {
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

  String _viewSelectionKey(String uid) =>
      '${CurrentUserService._viewSelectionPrefKeyPrefix}_$uid';

  int? _extractRequestedViewSelection(Map<String, dynamic> fields) {
    final raw = fields['viewSelection'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw == null || raw is FieldValue) return null;
    return int.tryParse(raw.toString());
  }

  Future<void> _persistViewSelection(String uid, int selection) async {
    if (uid.isEmpty) return;
    _prefs ??= await SharedPreferences.getInstance();
    _lastKnownViewSelection = selection;
    viewSelectionRx.value = selection;
    await _prefs?.setInt(_viewSelectionKey(uid), selection);
  }

  Future<CurrentUserModel> _applyStoredViewSelection(
    CurrentUserModel user,
  ) async {
    if (user.userID.isEmpty) return user;
    _prefs ??= await SharedPreferences.getInstance();
    final stored = _prefs?.getInt(_viewSelectionKey(user.userID));
    _lastKnownViewSelection = stored ?? user.viewSelection;
    if (stored == null || stored == user.viewSelection) {
      return user;
    }
    return user.copyWith(viewSelection: stored);
  }

  Future<void> _primeViewSelectionFromFirestore(String uid) async {
    if (uid.isEmpty) return;
    try {
      final hasLocalSelection = _lastKnownViewSelection != null;
      if (hasLocalSelection) {
        return;
      }
      final data = await _readRootUserData(uid, preferCache: true);
      if (data.isEmpty) return;
      final raw = data['viewSelection'];
      final remote = raw is int
          ? raw
          : raw is num
              ? raw.toInt()
              : int.tryParse(raw?.toString() ?? '');
      if (remote == null) return;

      await _persistViewSelection(uid, remote);
      final current = _currentUser;
      if (current != null &&
          current.userID == uid &&
          current.viewSelection != remote) {
        await _updateUser(current.copyWith(viewSelection: remote));
      }
    } catch (e, st) {
      _logSilently('prime.viewSelection', e, st);
    }
  }
}
