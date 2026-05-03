part of 'social_profile_controller.dart';

extension SocialProfileControllerProfilePart on SocialProfileController {
  bool _hasCanonicalProfileCounters(Map<String, dynamic> raw) {
    return _hasCounterKey(raw, 'counterOfFollowers') &&
        _hasCounterKey(raw, 'counterOfFollowings') &&
        _hasCounterKey(raw, 'counterOfPosts') &&
        _hasCounterKey(raw, 'counterOfLikes') &&
        _hasCounterKey(raw, 'counterOfListings');
  }

  int? _extractCounterValue(
    Map<String, dynamic> raw,
    List<String> keys,
  ) {
    final stats = (raw["stats"] is Map)
        ? Map<String, dynamic>.from(raw["stats"] as Map)
        : const <String, dynamic>{};
    for (final key in keys) {
      final direct = raw[key];
      if (direct is num) return direct.toInt();
      final nested = stats[key];
      if (nested is num) return nested.toInt();
    }
    return null;
  }

  bool _hasCounterKey(
    Map<String, dynamic> raw,
    String key,
  ) {
    if (raw.containsKey(key)) return true;
    final stats = (raw["stats"] is Map)
        ? Map<String, dynamic>.from(raw["stats"] as Map)
        : const <String, dynamic>{};
    return stats.containsKey(key);
  }

  int? _extractExactNumericCounter(
    Map<String, dynamic> raw,
    String key,
  ) {
    final direct = raw[key];
    if (direct is num) return direct.toInt();
    final stats = (raw["stats"] is Map)
        ? Map<String, dynamic>.from(raw["stats"] as Map)
        : const <String, dynamic>{};
    final nested = stats[key];
    if (nested is num) return nested.toInt();
    return null;
  }

  Future<void> _performLogProfileVisitIfNeeded() async {
    try {
      final current = CurrentUserService.instance.effectiveUserId;
      if (current.isEmpty) return;
      if (current == userID) return;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await _userSubcollectionRepository.upsertEntry(
        userID,
        subcollection: 'ProfileVisits',
        docId: '${current}_$nowMs',
        data: {
          'visitorId': current,
          'timeStamp': nowMs,
        },
      );
    } catch (e) {
      print('Profile visit log error: $e');
    }
  }

  Future<void> _performGetCounters() async {
    try {
      _pruneCaches();
      final cached = _counterCache[userID];
      if (cached != null &&
          DateTime.now().difference(cached.cachedAt) <= _counterCacheTtl) {
        totalFollower.value = cached.followers;
        totalFollowing.value = cached.followings;
        return;
      }

      final raw = await _userRepository.getPublicUserRaw(
        userID,
        preferCache: true,
        cacheOnly: true,
      );
      final rawMap = raw ?? const <String, dynamic>{};
      final followerCounter = _extractCounterValue(rawMap, <String>[
            'counterOfFollowers',
          ]);
      final followingCounter = _extractCounterValue(rawMap, <String>[
            'counterOfFollowings',
          ]);

      if (followerCounter != null) {
        totalFollower.value = followerCounter;
      }
      if (followingCounter != null) {
        totalFollowing.value = followingCounter;
      }

      if (raw == null ||
          raw.isEmpty ||
          !_hasCounterKey(rawMap, 'counterOfFollowers') ||
          !_hasCounterKey(rawMap, 'counterOfFollowings')) {
        final freshRaw = await _userRepository.getPublicUserRaw(
          userID,
          preferCache: false,
          forceServer: true,
        );
        final freshMap = freshRaw ?? const <String, dynamic>{};
        final freshFollowers = _extractCounterValue(freshMap, <String>[
          'counterOfFollowers',
        ]);
        final freshFollowings = _extractCounterValue(freshMap, <String>[
          'counterOfFollowings',
        ]);
        if (freshFollowers != null) {
          totalFollower.value = freshFollowers;
        }
        if (freshFollowings != null) {
          totalFollowing.value = freshFollowings;
        }
      }

      if (raw == null ||
          raw.isEmpty ||
          (totalFollower.value <= 0 && totalFollowing.value <= 0)) {
        final followers = await _followRepository.getFollowerIds(
          userID,
          preferCache: true,
          forceRefresh: false,
        );
        final followings = await _visibilityPolicy.loadViewerFollowingIds(
          viewerUserId: userID,
          preferCache: true,
          forceRefresh: false,
        );
        totalFollower.value = followers.length;
        totalFollowing.value = followings.length;
      }
      _counterCache[userID] = _SocialCounterCacheEntry(
        followers: totalFollower.value,
        followings: totalFollowing.value,
        cachedAt: DateTime.now(),
      );
    } catch (e) {
      print("⚠️ SocialProfile getCounters error: $e");
    }
  }

  Future<void> _performGetReshares() async {
    _resharesSub?.cancel();
    _resharesSub = _linkService.listenResharedPosts(userID).listen((refs) {
      _hydrateReshares(refs);
    });
  }

  Future<void> _performHydrateReshares(List<UserPostReference> refs) async {
    try {
      final posts = await _linkService.fetchResharedPosts(userID, refs);
      reshares.value = posts;
      bootstrapFeedPlaybackAfterDataChange();
    } catch (e) {
      print('SocialProfileController hydrate reshares error: $e');
    }
  }

  Future<void> _performIsFollowingCheck() async {
    final currentUid = CurrentUserService.instance.effectiveUserId;
    if (currentUid.isEmpty) {
      takipEdiyorum.value = false;
      complatedCheck.value = true;
      postNotificationsEnabled.value = false;
      return;
    }
    _pruneCaches();
    final cacheKey = '$currentUid:$userID';
    final cached = _followCheckCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _followCheckCacheTtl) {
      takipEdiyorum.value = cached.isFollowing;
      complatedCheck.value = true;
      if (cached.isFollowing) {
        unawaited(refreshPostNotificationSubscription());
      } else {
        postNotificationsEnabled.value = false;
      }
    }
    final isFollowing = await ensureFollowRepository().isFollowing(
      userID,
      currentUid: currentUid,
      preferCache: false,
    );
    takipEdiyorum.value = isFollowing;
    complatedCheck.value = true;
    if (isFollowing) {
      await refreshPostNotificationSubscription();
    } else {
      postNotificationsEnabled.value = false;
    }
    _followCheckCache[cacheKey] = _SocialFollowCheckCacheEntry(
      isFollowing: isFollowing,
      cachedAt: DateTime.now(),
    );
  }

  Future<void> _performRefreshPostNotificationSubscription() async {
    final currentUid = CurrentUserService.instance.effectiveUserId;
    if (currentUid.isEmpty ||
        currentUid == userID ||
        takipEdiyorum.value == false) {
      postNotificationsEnabled.value = false;
      return;
    }

    try {
      postNotificationsEnabled.value = await NotificationsRepository.ensure()
          .hasAuthorPostSubscription(userID, currentUid);
    } catch (e) {
      postNotificationsEnabled.value = false;
      print('SocialProfile refreshPostNotificationSubscription error: $e');
    }
  }

  Future<void> _performGetUserData() async {
    _userDocSub?.cancel();
    _userDocSub = _userRepository.watchPublicUserRaw(userID).listen((raw) {
      if (raw == null || raw.isEmpty) return;
      _applyUserData(raw);
    });
    try {
      final cachedRaw = await _userRepository.getPublicUserRaw(
        userID,
        preferCache: true,
        cacheOnly: true,
      );
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        _applyUserData(cachedRaw);
      }

      final shouldForceFreshAfterCache = cachedRaw == null ||
          cachedRaw.isEmpty ||
          !_hasCanonicalProfileCounters(cachedRaw);

      final raw = await _userRepository.getPublicUserRaw(
        userID,
        preferCache: !shouldForceFreshAfterCache,
        forceServer: shouldForceFreshAfterCache,
      );
      if (raw != null && raw.isNotEmpty) {
        _applyUserData(raw);
        if (_needsHeaderSupplementalData(raw) ||
            !_hasCanonicalProfileCounters(raw)) {
          final freshRaw = await _userRepository.getPublicUserRaw(
            userID,
            preferCache: false,
            forceServer: true,
          );
          if (freshRaw != null && freshRaw.isNotEmpty) {
            await _userRepository.putUserRaw(userID, freshRaw);
            _applyUserData(freshRaw);
          }
        } else {
          _applySupplementalUserData(raw);
        }
        return;
      }

      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (summary != null) {
        final bootstrapData = summary.toMap();
        if (bootstrapData.isNotEmpty) {
          _applyUserData(bootstrapData);
        }
        if (_needsHeaderSupplementalData(bootstrapData) ||
            !_hasCanonicalProfileCounters(bootstrapData)) {
          final freshRaw = await _userRepository.getPublicUserRaw(
            userID,
            preferCache: false,
            forceServer: true,
          );
          if (freshRaw != null && freshRaw.isNotEmpty) {
            await _userRepository.putUserRaw(userID, freshRaw);
            _applyUserData(freshRaw);
          }
        } else {
          _applySupplementalUserData(bootstrapData);
        }
        return;
      }
    } catch (e) {
      print('SocialProfile.getUserData resolver error: $e');
    }

    try {
      final raw = await _userRepository.getPublicUserRaw(
        userID,
        preferCache: true,
      );
      _applyUserData(raw ?? const <String, dynamic>{});
    } catch (e) {
      print("SocialProfile.getUserData fallback error: $e");
    }
  }

  bool _performNeedsHeaderSupplementalData(Map<String, dynamic> raw) {
    final profile = (raw["profile"] is Map)
        ? Map<String, dynamic>.from(raw["profile"] as Map)
        : const <String, dynamic>{};
    final bioText = (raw["bio"] ?? profile["bio"] ?? "").toString().trim();
    final meslekText =
        (raw["meslekKategori"] ?? profile["meslekKategori"] ?? "")
            .toString()
            .trim();
    return bioText.isEmpty || meslekText.isEmpty;
  }

  void _performApplyUserData(Map<String, dynamic> raw) {
    final profile = (raw["profile"] is Map)
        ? Map<String, dynamic>.from(raw["profile"] as Map)
        : const <String, dynamic>{};

    nickname.value = _resolveNickname(raw, profile);
    displayName.value =
        (raw["displayName"] ?? profile["displayName"] ?? "").toString().trim();
    avatarUrl.value = resolveAvatarUrl(raw, profile: profile);
    final nextDisplay = displayName.value;
    if (nextDisplay.isNotEmpty) {
      firstName.value = nextDisplay;
      lastName.value = "";
    } else {
      firstName.value =
          (raw["firstName"] ?? profile["firstName"] ?? "").toString();
      lastName.value =
          (raw["lastName"] ?? profile["lastName"] ?? "").toString();
    }
    rozet.value = (raw["rozet"] ?? profile["rozet"] ?? "").toString();
    bio.value = (raw["bio"] ?? profile["bio"] ?? "").toString();
    adres.value = "";
    meslek.value =
        (raw["meslekKategori"] ?? profile["meslekKategori"] ?? "").toString();
    final followerCount = _extractCounterValue(raw, <String>[
      'counterOfFollowers',
    ]);
    final followingCount = _extractCounterValue(raw, <String>[
      'counterOfFollowings',
    ]);
    if (followerCount != null) {
      totalFollower.value = followerCount;
    }
    if (followingCount != null) {
      totalFollowing.value = followingCount;
    }
    if (followerCount != null || followingCount != null) {
      _counterCache[userID] = _SocialCounterCacheEntry(
        followers: totalFollower.value,
        followings: totalFollowing.value,
        cachedAt: DateTime.now(),
      );
    }

    totalMarket.value = 0;
    final postsCount = _extractExactNumericCounter(raw, 'counterOfPosts');
    final likesCount = _extractExactNumericCounter(raw, 'counterOfLikes');
    final listingsCount = _extractExactNumericCounter(raw, 'counterOfListings');
    if (postsCount != null) {
      totalPosts.value = postsCount;
    }
    if (likesCount != null) {
      totalLikes.value = likesCount;
    }
    if (listingsCount != null) {
      totalMarket.value = listingsCount;
    }
    _applySupplementalUserData(raw);
  }

  void _performApplySupplementalUserData(Map<String, dynamic> raw) {
    email.value = "";
    token.value = "";
    phoneNumber.value = "";
    mailIzin.value = false;
    aramaIzin.value = false;
    ban.value = (raw["isBanned"] ?? raw["ban"] ?? false) == true;
    gizliHesap.value = (raw["isPrivate"] ?? raw["gizliHesap"] ?? false) == true;
    hesapOnayi.value =
        (raw["isApproved"] ?? raw["hesapOnayi"] ?? false) == true;
    blockedUsers.clear();
    final postsCount = _extractExactNumericCounter(raw, 'counterOfPosts');
    final likesCount = _extractExactNumericCounter(raw, 'counterOfLikes');
    final listingsCount = _extractExactNumericCounter(raw, 'counterOfListings');
    if (postsCount != null) {
      totalPosts.value = postsCount;
    }
    if (likesCount != null) {
      totalLikes.value = likesCount;
    }
    if (listingsCount != null) {
      totalMarket.value = listingsCount;
    }
    final followerCount = _extractCounterValue(raw, <String>[
      'counterOfFollowers',
    ]);
    final followingCount = _extractCounterValue(raw, <String>[
      'counterOfFollowings',
    ]);
    if (followerCount != null) {
      totalFollower.value = followerCount;
    }
    if (followingCount != null) {
      totalFollowing.value = followingCount;
    }
  }

  void _performPruneCaches() {
    final now = DateTime.now();
    bool isStale(DateTime t) => now.difference(t) > _cacheStaleRetention;
    _followCheckCache.removeWhere((_, v) => isStale(v.cachedAt));
    _counterCache.removeWhere((_, v) => isStale(v.cachedAt));
    _trimMap(_followCheckCache, (v) => v.cachedAt);
    _trimMap(_counterCache, (v) => v.cachedAt);
  }

  void _performTrimMap<T>(
    Map<String, T> map,
    DateTime Function(T value) cachedAt,
  ) {
    if (map.length <= _maxCacheEntries) return;
    final entries = map.entries.toList()
      ..sort((a, b) => cachedAt(a.value).compareTo(cachedAt(b.value)));
    final removeCount = map.length - _maxCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      map.remove(entries[i].key);
    }
  }
}
