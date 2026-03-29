part of 'story_repository.dart';

extension StoryRepositoryCachePart on StoryRepository {
  int _storyRowCacheAsInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _storyRowCacheAsBool(Object? value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final raw = value?.toString().trim().toLowerCase();
    if (raw == 'true' || raw == '1') return true;
    if (raw == 'false' || raw == '0') return false;
    return fallback;
  }

  Future<StoryFetchResult> _performFetchStoryUsers({
    required int limit,
    required bool cacheFirst,
    required String currentUid,
    required List<String> blockedUserIds,
  }) async {
    QuerySnapshot<Map<String, dynamic>> snap;
    var cacheHit = false;

    if (cacheFirst) {
      snap = await PerformanceService.traceOperation(
        'story_load_cache_first',
        () => FirebaseFirestore.instance
            .collection('stories')
            .orderBy('createdDate', descending: true)
            .limit(limit)
            .get(const GetOptions(source: Source.cache)),
      );
      cacheHit = snap.docs.isNotEmpty;

      if (snap.docs.isEmpty) {
        snap = await PerformanceService.traceOperation(
          'story_load_network_fallback',
          () => FirebaseFirestore.instance
              .collection('stories')
              .orderBy('createdDate', descending: true)
              .limit(limit)
              .get(),
        );
      }
    } else {
      snap = await PerformanceService.traceOperation(
        'story_load_network',
        () => FirebaseFirestore.instance
            .collection('stories')
            .orderBy('createdDate', descending: true)
            .limit(limit)
            .get(),
      );
    }

    final userStories = <String, List<StoryModel>>{};
    final storyEmbeddedUserMeta = <String, Map<String, dynamic>>{};
    final expiry = DateTime.now().subtract(const Duration(hours: 24));

    for (final doc in snap.docs) {
      try {
        final data = doc.data();
        if (_storyRowCacheAsBool(data['deleted'])) continue;
        final story = StoryModel.fromDoc(doc);
        if (story.createdAt.isBefore(expiry)) continue;
        userStories.putIfAbsent(story.userId, () => <StoryModel>[]);
        userStories[story.userId]!.add(story);

        final embeddedNickname = (data['nickname'] ?? '').toString().trim();
        final embeddedAvatar = (data['avatarUrl'] ?? '').toString().trim();
        final embeddedUsername = (data['username'] ?? '').toString().trim();
        if (embeddedNickname.isNotEmpty ||
            embeddedAvatar.isNotEmpty ||
            embeddedUsername.isNotEmpty) {
          storyEmbeddedUserMeta[story.userId] = <String, dynamic>{
            'nickname': embeddedNickname,
            'avatarUrl': embeddedAvatar,
            'username': embeddedUsername,
            'firstName': (data['firstName'] ?? '').toString(),
            'lastName': (data['lastName'] ?? '').toString(),
            'isPrivate': _storyRowCacheAsBool(data['isPrivate']),
          };
        }
      } catch (_) {}
    }

    final userIds = userStories.keys.toList(growable: false);
    final userDataMap = await _userCache.getProfiles(
      userIds,
      preferCache: true,
      cacheOnly: false,
    );
    final missingUserIds =
        userIds.where((id) => userDataMap[id] == null).toList(growable: false);
    if (missingUserIds.isNotEmpty) {
      userDataMap.addAll(await _loadMissingProfilesFromUsers(missingUserIds));
    }

    final followingIds =
        await VisibilityPolicyService.ensure().loadViewerFollowingIds(
      viewerUserId: currentUid,
      preferCache: true,
    );
    final blockedSet = blockedUserIds.toSet();
    final current = CurrentUserService.instance;
    final users = <StoryUserModel>[];

    for (final entry in userStories.entries) {
      final userId = entry.key;
      if (blockedSet.contains(userId)) continue;

      final stories = [...entry.value]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final rawData = userDataMap[userId] ?? storyEmbeddedUserMeta[userId];
      final data = Map<String, dynamic>.from(
        rawData ?? _fallbackUserData(userId, current),
      );

      final isPrivate = _storyRowCacheAsBool(data['isPrivate']);
      final canSeeAuthor = _visibilityPolicy.canViewerSeeAuthorFromSummary(
        authorUserId: userId,
        followingIds: followingIds,
        isPrivate: isPrivate,
        isDeleted: false,
      );
      if (!canSeeAuthor) continue;

      final resolvedNickname = _resolveStoryNickname(data).trim();
      users.add(
        StoryUserModel(
          nickname: resolvedNickname.isNotEmpty
              ? resolvedNickname
              : (data['nickname']?.toString().trim().isNotEmpty == true
                  ? data['nickname'].toString().trim()
                  : (currentUid.isNotEmpty && userId == currentUid
                      ? (current.nickname.isNotEmpty ? current.nickname : 'sen')
                      : 'kullanici')),
          avatarUrl: _resolveAvatar(data),
          fullName: "${data['firstName'] ?? ""} ${data['lastName'] ?? ""}",
          userID: userId,
          stories: stories,
        ),
      );
    }

    final cachePayload = <String, dynamic>{
      'event': cacheHit ? 'scopedSnapshotHit' : 'liveSyncSucceeded',
      'surfaceKey': 'story_row_snapshot',
      'hasScope': false,
      'isUserScoped': false,
      'source': cacheHit ? 'firestoreCache' : 'server',
      'hasData': users.isNotEmpty,
      'hasLocalSnapshot': cacheHit,
      'isRefreshing': false,
      'isStale': false,
      'hasLiveError': false,
      'itemCount': users.length,
      'requestedLimit': limit,
    };
    final playbackKpi = maybeFindPlaybackKpiService();
    if (playbackKpi != null) {
      playbackKpi.track(
        PlaybackKpiEventType.cacheFirstLifecycle,
        cachePayload,
      );
    }
    recordQALabCacheFirstEvent(cachePayload);

    return StoryFetchResult(users: users, cacheHit: cacheHit);
  }

  Future<void> _performSaveStoryRowCache(
    List<StoryUserModel> list, {
    required String ownerUid,
  }) async {
    if (list.isEmpty) return;
    await _ensureInitialized();
    final path = _storyRowCachePathForOwner(ownerUid);
    if (path == null) return;
    try {
      final payload = {
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'ownerUid': ownerUid,
        'users': list.map((u) => u.toCacheMap()).toList(),
      };
      final file = File(path);
      final tmp = File('$path.tmp');
      await tmp.writeAsString(jsonEncode(payload), flush: true);
      await tmp.rename(file.path);
    } catch (_) {}
  }

  Future<List<StoryUserModel>> _performRestoreStoryRowCache({
    required String ownerUid,
    required bool allowExpired,
  }) async {
    await _ensureInitialized();
    final path = _storyRowCachePathForOwner(ownerUid);
    if (path == null) return const <StoryUserModel>[];
    final file = File(path);
    try {
      if (!await file.exists()) return const <StoryUserModel>[];
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        await file.delete();
        return const <StoryUserModel>[];
      }
      final data = jsonDecode(raw);
      if (data is! Map) {
        await file.delete();
        return const <StoryUserModel>[];
      }
      final cacheOwnerUid = (data['ownerUid'] ?? '').toString();
      if (cacheOwnerUid.isNotEmpty && cacheOwnerUid != ownerUid) {
        await file.delete();
        return const <StoryUserModel>[];
      }
      final savedAt = _storyRowCacheAsInt(data['savedAt']);
      if (!allowExpired && savedAt > 0) {
        final age = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(savedAt),
        );
        if (age > storyRowCacheTtlInternal) {
          await file.delete();
          return const <StoryUserModel>[];
        }
      }
      final usersJson = data['users'];
      if (usersJson is! List) {
        await file.delete();
        return const <StoryUserModel>[];
      }
      final expiryCutoff = storyExpiryCutoffInternal;
      var shouldPersist = false;
      final restoredUsers = <StoryUserModel>[];
      for (final rawUser in usersJson) {
        if (rawUser is! Map) {
          shouldPersist = true;
          continue;
        }
        try {
          var user = StoryUserModel.fromCacheMap(
            Map<String, dynamic>.from(rawUser.cast<dynamic, dynamic>()),
          );
          if (user.userID.isEmpty) {
            shouldPersist = true;
            continue;
          }
          if (!allowExpired) {
            final activeStories = user.stories
                .where((story) => story.createdAt.isAfter(expiryCutoff))
                .toList(growable: false)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            if (activeStories.length != user.stories.length) {
              shouldPersist = true;
            }
            user = StoryUserModel(
              nickname: user.nickname,
              avatarUrl: user.avatarUrl,
              fullName: user.fullName,
              userID: user.userID,
              stories: activeStories,
            );
          }
          if (user.stories.isEmpty && user.userID != ownerUid) {
            shouldPersist = true;
            continue;
          }
          restoredUsers.add(user);
        } catch (_) {
          shouldPersist = true;
        }
      }
      if (restoredUsers.isEmpty) {
        await file.delete();
        return const <StoryUserModel>[];
      }
      if (shouldPersist || restoredUsers.length != usersJson.length) {
        await _performSaveStoryRowCache(
          restoredUsers,
          ownerUid: ownerUid,
        );
      }
      return restoredUsers;
    } catch (_) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      return const <StoryUserModel>[];
    }
  }

  Future<void> _performClearStoryRowCacheForCurrentUser(String ownerUid) async {
    await _ensureInitialized();
    final path = _storyRowCachePathForOwner(ownerUid);
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> _performInvalidateStoryCachesForUser(
    String uid, {
    required bool clearDeletedStories,
  }) async {
    if (uid.trim().isEmpty) return;
    await clearStoryRowCacheForCurrentUser(uid);
    if (clearDeletedStories) {
      await clearDeletedStoriesCache(uid);
    }
  }

  Future<Map<String, StoryModel>> _performFetchStoriesByIds(
    List<String> storyIds,
  ) async {
    final ids = storyIds.where((e) => e.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const <String, StoryModel>{};
    final stories = <String, StoryModel>{};
    const chunkSize = 10;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize > ids.length) ? ids.length : i + chunkSize;
      final chunk = ids.sublist(i, end);
      final snap = await FirebaseFirestore.instance
          .collection('stories')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        try {
          final data = doc.data();
          if (_storyRowCacheAsBool(data['deleted'])) continue;
          final story = StoryModel.fromDoc(doc);
          stories[story.id] = story;
        } catch (_) {}
      }
    }
    return stories;
  }

  Future<StoryModel?> _performFetchStoryById(
    String storyId, {
    required bool preferCache,
  }) async {
    final raw = await getStoryRaw(storyId, preferCache: preferCache);
    if (raw == null || raw.isEmpty) return null;
    return StoryModel.fromCacheMap(<String, dynamic>{
      'id': storyId,
      ...raw,
    });
  }

  Future<List<StoryModel>> _performFetchActiveStoriesByMusicId(
    String musicId, {
    required int limit,
  }) async {
    final cleanId = musicId.trim();
    if (cleanId.isEmpty) return const <StoryModel>[];
    final snap = await FirebaseFirestore.instance
        .collection('stories')
        .where('musicId', isEqualTo: cleanId)
        .limit(limit)
        .get();
    final expiry = DateTime.now().subtract(const Duration(hours: 24));
    return snap.docs
        .map((doc) {
          try {
            final data = doc.data();
            if ((data['deleted'] ?? false) == true) {
              return null;
            }
            return StoryModel.fromDoc(doc);
          } catch (_) {
            return null;
          }
        })
        .whereType<StoryModel>()
        .where((story) => story.createdAt.isAfter(expiry))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>?> _performGetStoryRaw(
    String storyId, {
    required bool preferCache,
  }) async {
    if (storyId.isEmpty) return null;
    if (preferCache) {
      try {
        final cached = await FirebaseFirestore.instance
            .collection('stories')
            .doc(storyId)
            .get(const GetOptions(source: Source.cache));
        if (cached.exists) {
          return Map<String, dynamic>.from(cached.data() ?? const {});
        }
      } catch (_) {}
    }
    final server = await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .get();
    if (!server.exists) return null;
    return Map<String, dynamic>.from(server.data() ?? const {});
  }

  Future<List<StoryModel>> _performGetStoriesForUser(
    String userId, {
    required bool preferCache,
    required bool includeDeleted,
  }) async {
    if (userId.isEmpty) return const <StoryModel>[];

    Future<QuerySnapshot<Map<String, dynamic>>> runQuery(GetOptions? options) {
      final query = FirebaseFirestore.instance
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .orderBy('createdDate', descending: true);
      if (options == null) return query.get();
      return query.get(options);
    }

    QuerySnapshot<Map<String, dynamic>> snap;
    if (preferCache) {
      try {
        snap = await runQuery(const GetOptions(source: Source.cache));
        if (snap.docs.isEmpty) {
          snap = await runQuery(null);
        }
      } catch (_) {
        snap = await runQuery(null);
      }
    } else {
      snap = await runQuery(null);
    }

    final expiryCutoff = storyExpiryCutoffInternal;
    final stories = snap.docs
        .where(
          (doc) => includeDeleted || (doc.data()['deleted'] ?? false) != true,
        )
        .map(StoryModel.fromDoc)
        .where(
          (story) => includeDeleted || story.createdAt.isAfter(expiryCutoff),
        )
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return stories;
  }
}
