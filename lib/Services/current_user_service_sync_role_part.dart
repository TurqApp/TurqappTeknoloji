part of 'current_user_service.dart';

class CurrentUserSyncRole {
  CurrentUserSyncRole(
    this.service, {
    StartupSessionFailureReporter? failureReporter,
  }) : _failureReporter =
            failureReporter ?? StartupSessionFailureReporter.defaultReporter;

  final CurrentUserService service;
  final StartupSessionFailureReporter _failureReporter;

  Future<bool> initialize() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      final firebaseUser = service.currentAuthUser;
      if (firebaseUser == null) {
        await service._clearActiveCachePointer();
        service._currentUser = null;
        service.currentUserRx.value = null;
        if (!service._userStreamController.isClosed) {
          service._userStreamController.add(null);
        }
        _lastReactiveSignature = null;
        _lastRootSyncSignature = null;
        _isInitialized = true;
        emailVerifiedRx.value = true;
        return false;
      }
      emailVerifiedRx.value = firebaseUser.emailVerified;
      unawaited(
          CurrentUserAccountCenterRole(service).adoptFreshSessionKeyIfNeeded());
      _lastKnownViewSelection =
          _prefs?.getInt(service._viewSelectionKey(firebaseUser.uid));
      service.viewSelectionRx.value = _lastKnownViewSelection ?? 1;

      if (_isInitialized &&
          service._currentUser != null &&
          service._currentUser!.userID == firebaseUser.uid) {
        if (!_isSyncing) {
          unawaited(startFirebaseSync());
        }
        unawaited(
            service.refreshEmailVerificationStatus(reloadAuthUser: false));
        unawaited(service._loadEmailVerifyConfig());
        return true;
      }

      if (service._currentUser != null &&
          service._currentUser!.userID != firebaseUser.uid) {
        service._currentUser = null;
        service.currentUserRx.value = null;
        if (!service._userStreamController.isClosed) {
          service._userStreamController.add(null);
        }
        _lastReactiveSignature = null;
        _lastRootSyncSignature = null;
      }
      final cacheLoaded = await CurrentUserCacheStore(service)
          .loadFromCache(expectedUid: firebaseUser.uid);

      await service
          ._primeViewSelectionFromFirestore(firebaseUser.uid)
          .timeout(const Duration(milliseconds: 350), onTimeout: () {});

      unawaited(service.refreshEmailVerificationStatus(reloadAuthUser: false));
      unawaited(service._loadEmailVerifyConfig());
      unawaited(startFirebaseSync());

      _isInitialized = true;
      return cacheLoaded || service.isLoggedIn;
    } catch (error, stackTrace) {
      _failureReporter.record(
        kind: StartupSessionFailureKind.sessionInitialize,
        operation: 'CurrentUserSyncRole.initialize',
        error: error,
        stackTrace: stackTrace,
      );
      _isInitialized = true;
      return false;
    }
  }

  Future<void> forceRefresh() async {
    final firebaseUser = service.currentAuthUser;
    if (firebaseUser == null) return;

    try {
      CurrentUserCacheStore(service).purgeUserScopedCaches(firebaseUser.uid);
      final data = await CurrentUserCacheStore(service).readRootUserData(
        firebaseUser.uid,
        preferCache: false,
        forceServer: true,
      );

      if (data.isNotEmpty) {
        final merged = await buildMergedUserData(
          uid: firebaseUser.uid,
          rootData: data,
        );
        await service._updateUser(CurrentUserModel.fromJson(merged));
      }
      await service.refreshEmailVerificationStatus(reloadAuthUser: true);
    } catch (error, stackTrace) {
      _failureReporter.record(
        kind: StartupSessionFailureKind.sessionForceRefresh,
        operation: 'CurrentUserSyncRole.forceRefresh',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> startFirebaseSync() async {
    if (_isSyncing) return;

    final firebaseUser = service.currentAuthUser;
    if (firebaseUser == null) return;

    try {
      _isSyncing = true;
      await _firestoreSubscription?.cancel();

      _firestoreSubscription =
          UserRepository.ensure().watchUserRaw(firebaseUser.uid).listen(
        (data) async {
          if (data == null || data.isEmpty) {
            return;
          }
          if (await CurrentUserAccountCenterRole(service)
              .handleExclusiveSessionIfNeeded(firebaseUser.uid, data)) {
            return;
          }
          final rootSignature = jsonEncode(data);
          if (service._currentUser?.userID == firebaseUser.uid &&
              _lastRootSyncSignature == rootSignature) {
            return;
          }
          CurrentUserCacheStore(service)
              .storeRootUserData(firebaseUser.uid, data);
          _lastRootSyncSignature = rootSignature;

          final merged = await buildMergedUserData(
            uid: firebaseUser.uid,
            rootData: data,
          );
          final user = CurrentUserModel.fromJson(merged);
          await service._updateUser(user);
        },
        onError: (error, stackTrace) {
          _failureReporter.record(
            kind: StartupSessionFailureKind.sessionSyncStream,
            operation: 'CurrentUserSyncRole.startFirebaseSync.listen',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
      startExclusiveSessionHeartbeat(firebaseUser.uid);
      unawaited(
          CurrentUserAccountCenterRole(service).adoptFreshSessionKeyIfNeeded());
      unawaited(validateExclusiveSessionFromServer(firebaseUser.uid));
    } catch (error, stackTrace) {
      _failureReporter.record(
        kind: StartupSessionFailureKind.sessionSyncStart,
        operation: 'CurrentUserSyncRole.startFirebaseSync',
        error: error,
        stackTrace: stackTrace,
      );
      _isSyncing = false;
    }
  }

  void startExclusiveSessionHeartbeat(String uid) {
    _exclusiveSessionHeartbeat?.cancel();
    _exclusiveSessionHeartbeat = Timer.periodic(
      _exclusiveSessionHeartbeatInterval,
      (_) => unawaited(validateExclusiveSessionFromServer(uid)),
    );
  }

  Future<void> validateExclusiveSessionFromServer(String uid) async {
    if (uid.trim().isEmpty || _handlingSessionDisplacement) return;
    try {
      final raw = await UserRepository.ensure().getUserRaw(
        uid,
        preferCache: false,
        forceServer: true,
      );
      if (raw == null || raw.isEmpty) return;
      await CurrentUserAccountCenterRole(service)
          .handleExclusiveSessionIfNeeded(uid, raw);
    } catch (error, stackTrace) {
      _failureReporter.record(
        kind: StartupSessionFailureKind.sessionServerValidation,
        operation: 'CurrentUserSyncRole.validateExclusiveSessionFromServer',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Map<String, dynamic>> buildMergedUserData({
    required String uid,
    required Map<String, dynamic> rootData,
  }) async {
    dynamic cloneValue(dynamic value) {
      if (value is Map) {
        return value.map(
          (key, nestedValue) =>
              MapEntry(key.toString(), cloneValue(nestedValue)),
        );
      }
      if (value is List) {
        return value.map(cloneValue).toList(growable: false);
      }
      return value;
    }

    Map<String, dynamic> cloneMap(Map<String, dynamic> source) {
      return source.map((key, value) => MapEntry(key, cloneValue(value)));
    }

    final merged = cloneMap(rootData);
    final currentSnapshot =
        (service._currentUser != null && service._currentUser!.userID == uid)
            ? service._currentUser!.toJson()
            : const <String, dynamic>{};

    Map<String, dynamic> extractRootMap(String key) {
      final raw = merged[key];
      if (raw is Map<String, dynamic>) return cloneMap(raw);
      if (raw is Map) {
        return cloneMap(
          raw.map((mapKey, value) => MapEntry(mapKey.toString(), value)),
        );
      }
      return <String, dynamic>{};
    }

    Map<String, dynamic> extractCurrentMap(String key) {
      final raw = currentSnapshot[key];
      if (raw is Map<String, dynamic>) return cloneMap(raw);
      if (raw is Map) {
        return cloneMap(
          raw.map((mapKey, value) => MapEntry(mapKey.toString(), value)),
        );
      }
      return <String, dynamic>{};
    }

    Future<Map<String, dynamic>> readSubdocCached(
      String col,
      String doc,
    ) async {
      final repository = ensureUserSubdocRepository();
      try {
        final data = await repository.getDoc(
          uid,
          collection: col,
          docId: doc,
          preferCache: true,
          ttl: _subdocCacheTtl,
        );
        return data;
      } catch (e, st) {
        CurrentUserCacheStore(service).logSilently('subdoc.$col.$doc', e, st);
        return <String, dynamic>{};
      }
    }

    Future<Map<String, dynamic>> readListCache(
      String key,
      Future<Map<String, dynamic>> Function() loader,
    ) async {
      final cacheKey = CurrentUserCacheStore(service).listCacheKey(uid, key);
      final cached = _listCache[cacheKey];
      if (cached != null &&
          CurrentUserCacheStore(service)
              .isFresh(cached.fetchedAt, _listCacheTtl)) {
        return cloneMap(cached.value);
      }
      try {
        final loaded = await loader();
        _listCache[cacheKey] = _TimedValue<Map<String, dynamic>>(
          value: cloneMap(loaded),
          fetchedAt: DateTime.now(),
        );
        return cloneMap(loaded);
      } catch (e, st) {
        CurrentUserCacheStore(service).logSilently('subcol.$key', e, st);
        if (cached != null) {
          return cloneMap(cached.value);
        }
        return <String, dynamic>{};
      }
    }

    final rootPrivate = extractRootMap('private');
    final rootEducation = extractRootMap('education');
    final rootFamily = extractRootMap('family');
    final rootSettings = extractRootMap('settings');
    final rootStats = extractRootMap('stats');
    final currentPrivate = extractCurrentMap('private');
    final currentEducation = extractCurrentMap('education');
    final currentFamily = extractCurrentMap('family');
    final currentSettings = extractCurrentMap('settings');
    final currentStats = extractCurrentMap('stats');

    final privateAccount = rootPrivate.isNotEmpty
        ? rootPrivate
        : (currentPrivate.isNotEmpty
            ? currentPrivate
            : await readSubdocCached('private', 'account'));
    final education = rootEducation.isNotEmpty
        ? rootEducation
        : (currentEducation.isNotEmpty
            ? currentEducation
            : await readSubdocCached('education', 'info'));
    final family = rootFamily.isNotEmpty
        ? rootFamily
        : (currentFamily.isNotEmpty
            ? currentFamily
            : await readSubdocCached('family', 'info'));
    final settings = rootSettings.isNotEmpty
        ? rootSettings
        : (currentSettings.isNotEmpty
            ? currentSettings
            : await readSubdocCached('settings', 'preferences'));
    final stats = rootStats.isNotEmpty
        ? rootStats
        : (currentStats.isNotEmpty
            ? currentStats
            : await readSubdocCached('stats', 'summary'));

    void mergeOverride(Map<String, dynamic> source) {
      source.forEach((k, v) {
        merged[k] = cloneValue(v);
      });
    }

    void mergeRootScope(String scope) {
      final raw = rootData[scope];
      if (raw is Map<String, dynamic>) {
        mergeOverride(raw);
        return;
      }
      if (raw is Map) {
        mergeOverride(
          raw.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    }

    mergeRootScope('profile');
    mergeRootScope('private');
    mergeRootScope('education');
    mergeRootScope('family');
    mergeRootScope('settings');
    mergeRootScope('stats');
    mergeRootScope('account');
    mergeRootScope('preferences');
    mergeRootScope('finance');

    mergeOverride(privateAccount);
    mergeOverride(education);
    mergeOverride(family);
    mergeOverride(settings);
    mergeOverride(stats);

    bool hasNonEmptyString(dynamic value) =>
        value is String && value.trim().isNotEmpty;

    void preferRootString(String key) {
      if (!rootData.containsKey(key)) return;
      final value = rootData[key];
      if (hasNonEmptyString(value)) {
        merged[key] = value;
      }
    }

    void preferCurrentString(String key) {
      if (hasNonEmptyString(merged[key])) return;
      final value = currentSnapshot[key];
      if (hasNonEmptyString(value)) {
        merged[key] = value;
      }
    }

    void preferRootScalar(String key) {
      if (!rootData.containsKey(key)) return;
      final value = rootData[key];
      if (value != null) {
        merged[key] = cloneValue(value);
      }
    }

    for (final key in const [
      'avatarUrl',
      'nickname',
      'nickName',
      'username',
      'userName',
      'usernameLower',
      'displayName',
      'firstName',
      'lastName',
      'email',
      'phoneNumber',
      'bio',
      'rozet',
      'badge',
      'meslekKategori',
      'token',
    ]) {
      preferRootString(key);
    }
    for (final key in const [
      'avatarUrl',
      'nickname',
      'nickName',
      'username',
      'userName',
      'usernameLower',
      'displayName',
      'firstName',
      'lastName',
      'email',
      'phoneNumber',
      'bio',
      'rozet',
      'badge',
      'meslekKategori',
      'token',
    ]) {
      preferCurrentString(key);
    }
    for (final key in const [
      'counterOfFollowers',
      'counterOfFollowings',
      'counterOfPosts',
      'counterOfLikes',
      'antPoint',
      'dailyDurations',
      'createdDate',
      'updatedDate',
      'viewSelection',
    ]) {
      preferRootScalar(key);
    }

    final currentBlocked = currentSnapshot['blockedUsers'];
    if (merged['blockedUsers'] is! List) {
      if (currentBlocked is List && currentBlocked.isNotEmpty) {
        merged['blockedUsers'] =
            currentBlocked.map((e) => e.toString()).toList(growable: false);
      } else {
        final blocked = await readListCache('blockedUsers', () async {
          final entries = await _userSubcollectionRepository.getEntries(
            uid,
            subcollection: 'blockedUsers',
            preferCache: true,
          );
          return <String, dynamic>{
            'blockedUsers': entries.map((d) => d.id).toList(growable: false),
          };
        });
        final list = blocked['blockedUsers'];
        if (list is List) {
          merged['blockedUsers'] = list.map((e) => e.toString()).toList();
        }
      }
    }

    final currentReadStories = currentSnapshot['readStories'];
    final currentReadStoriesTimes = currentSnapshot['readStoriesTimes'];
    if (merged['readStories'] is! List) {
      if (currentReadStories is List && currentReadStories.isNotEmpty) {
        merged['readStories'] =
            currentReadStories.map((e) => e.toString()).toList(growable: false);
        if (currentReadStoriesTimes is Map &&
            currentReadStoriesTimes.isNotEmpty) {
          final normalized = <String, int>{};
          currentReadStoriesTimes.forEach((k, v) {
            if (v is num) normalized[k.toString()] = v.toInt();
          });
          if (normalized.isNotEmpty) {
            merged['readStoriesTimes'] = normalized;
          }
        }
      } else {
        final readStories = await readListCache('readStories', () async {
          final entries = await _userSubcollectionRepository.getEntries(
            uid,
            subcollection: 'readStories',
            preferCache: true,
          );
          final times = <String, int>{};
          for (final entry in entries) {
            final t = entry.data['readDate'];
            if (t is num) times[entry.id] = t.toInt();
          }
          return <String, dynamic>{
            'readStories': entries.map((e) => e.id).toList(growable: false),
            'readStoriesTimes': times,
          };
        });
        final list = readStories['readStories'];
        if (list is List) {
          merged['readStories'] = list.map((e) => e.toString()).toList();
        }
        final times = readStories['readStoriesTimes'];
        if (times is Map) {
          final normalized = <String, int>{};
          times.forEach((k, v) {
            if (v is num) normalized[k.toString()] = v.toInt();
          });
          if (normalized.isNotEmpty) {
            merged['readStoriesTimes'] = normalized;
          }
        }
      }
    }

    final currentLastSearchList = currentSnapshot['lastSearchList'];
    if (merged['lastSearchList'] is! List) {
      if (currentLastSearchList is List && currentLastSearchList.isNotEmpty) {
        merged['lastSearchList'] = currentLastSearchList
            .map((e) => e.toString())
            .toList(growable: false);
      } else {
        final searches = await readListCache('lastSearches', () async {
          final entries = await _userSubcollectionRepository.getEntries(
            uid,
            subcollection: 'lastSearches',
            preferCache: true,
          );
          final docs = entries.toList()
            ..sort((a, b) {
              final aData = a.data;
              final bData = b.data;
              final aTs = (aData['updatedDate'] is num)
                  ? (aData['updatedDate'] as num).toInt()
                  : ((aData['timeStamp'] is num)
                      ? (aData['timeStamp'] as num).toInt()
                      : 0);
              final bTs = (bData['updatedDate'] is num)
                  ? (bData['updatedDate'] as num).toInt()
                  : ((bData['timeStamp'] is num)
                      ? (bData['timeStamp'] as num).toInt()
                      : 0);
              return bTs.compareTo(aTs);
            });
          return <String, dynamic>{
            'lastSearchList':
                docs.take(100).map((d) => d.id).toList(growable: false),
          };
        });
        final list = searches['lastSearchList'];
        if (list is List) {
          merged['lastSearchList'] = list.map((e) => e.toString()).toList();
        }
      }
    }

    return cloneMap(merged);
  }

  Future<void> stopFirebaseSync() async {
    await _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    _exclusiveSessionHeartbeat?.cancel();
    _exclusiveSessionHeartbeat = null;
    _isSyncing = false;
  }
}
