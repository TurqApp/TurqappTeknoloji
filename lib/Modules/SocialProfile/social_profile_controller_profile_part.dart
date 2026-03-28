part of 'social_profile_controller.dart';

DocumentReference<Map<String, dynamic>> _postNotificationSubscriberRef(
  String authorId,
  String subscriberUid,
) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(authorId)
      .collection('postNotificationSubscribers')
      .doc(subscriberUid);
}

extension SocialProfileControllerProfilePart on SocialProfileController {
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

      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      final followerCounter = summary?.followerCount ?? 0;
      final followingCounter = summary?.followingCount ?? 0;

      totalFollower.value = followerCounter;
      totalFollowing.value = followingCounter;

      if (totalFollower.value == 0 || totalFollowing.value == 0) {
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
      final entry = await _postNotificationSubscriberRef(userID, currentUid)
          .get(const GetOptions(source: Source.serverAndCache));
      postNotificationsEnabled.value = entry.exists;
    } catch (e) {
      postNotificationsEnabled.value = false;
      print('SocialProfile refreshPostNotificationSubscription error: $e');
    }
  }

  Future<void> _performGetUserData() async {
    _userDocSub?.cancel();
    try {
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (summary != null) {
        final cachedRaw = await _userRepository.getUserRaw(
          userID,
          preferCache: true,
          cacheOnly: true,
        );
        final bootstrapData = (cachedRaw != null && cachedRaw.isNotEmpty)
            ? cachedRaw
            : summary.toMap();
        _applyUserData(bootstrapData);
        if (_needsHeaderSupplementalData(bootstrapData)) {
          final raw = await _userRepository.getUserRaw(
            userID,
            preferCache: false,
            forceServer: true,
          );
          if (raw != null && raw.isNotEmpty) {
            await _userRepository.putUserRaw(userID, raw);
            _applyUserData(raw);
          }
        } else if (cachedRaw != null && cachedRaw.isNotEmpty) {
          _applySupplementalUserData(cachedRaw);
        }
        return;
      }
    } catch (e) {
      print('SocialProfile.getUserData resolver error: $e');
    }

    try {
      final raw = await _userRepository.getUserRaw(userID, preferCache: true);
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
    final addressText =
        (raw["adres"] ?? profile["adres"] ?? "").toString().trim();
    final meslekText =
        (raw["meslekKategori"] ?? profile["meslekKategori"] ?? "")
            .toString()
            .trim();
    return bioText.isEmpty || addressText.isEmpty || meslekText.isEmpty;
  }

  void _performApplyUserData(Map<String, dynamic> raw) {
    final profile = (raw["profile"] is Map)
        ? Map<String, dynamic>.from(raw["profile"] as Map)
        : const <String, dynamic>{};
    final stats = (raw["stats"] is Map)
        ? Map<String, dynamic>.from(raw["stats"] as Map)
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
    email.value = (raw["email"] ?? profile["email"] ?? "").toString();
    rozet.value = (raw["rozet"] ?? profile["rozet"] ?? "").toString();
    bio.value = (raw["bio"] ?? profile["bio"] ?? "").toString();
    adres.value = (raw["adres"] ?? profile["adres"] ?? "").toString();
    meslek.value =
        (raw["meslekKategori"] ?? profile["meslekKategori"] ?? "").toString();

    totalMarket.value = 0;
    final postsCount = raw["counterOfPosts"] ?? stats["counterOfPosts"] ?? 0;
    final likesCount = raw["counterOfLikes"] ?? stats["counterOfLikes"] ?? 0;
    totalPosts.value = (postsCount is num) ? postsCount.toInt() : 0;
    totalLikes.value = (likesCount is num) ? likesCount.toInt() : 0;
    _applySupplementalUserData(raw);
  }

  void _performApplySupplementalUserData(Map<String, dynamic> raw) {
    final profile = (raw["profile"] is Map)
        ? Map<String, dynamic>.from(raw["profile"] as Map)
        : const <String, dynamic>{};
    final preferences = (raw["preferences"] is Map)
        ? Map<String, dynamic>.from(raw["preferences"] as Map)
        : const <String, dynamic>{};
    final stats = (raw["stats"] is Map)
        ? Map<String, dynamic>.from(raw["stats"] as Map)
        : const <String, dynamic>{};

    email.value = (raw["email"] ?? profile["email"] ?? "").toString();
    token.value = (raw["token"] ?? "").toString();
    phoneNumber.value =
        (raw["phoneNumber"] ?? profile["phoneNumber"] ?? "").toString();
    mailIzin.value =
        (raw["mailIzin"] ?? preferences["mailIzin"] ?? false) == true;
    aramaIzin.value =
        (raw["aramaIzin"] ?? preferences["aramaIzin"] ?? false) == true;
    ban.value = (raw["isBanned"] ?? raw["ban"] ?? false) == true;
    gizliHesap.value = (raw["isPrivate"] ?? raw["gizliHesap"] ?? false) == true;
    hesapOnayi.value =
        (raw["isApproved"] ?? raw["hesapOnayi"] ?? false) == true;
    final blocked = raw["blockedUsers"];
    if (blocked is List) {
      blockedUsers.value = blocked.map((e) => e.toString()).toList();
    } else {
      blockedUsers.clear();
    }
    final postsCount = raw["counterOfPosts"] ?? stats["counterOfPosts"] ?? 0;
    final likesCount = raw["counterOfLikes"] ?? stats["counterOfLikes"] ?? 0;
    totalPosts.value =
        (postsCount is num) ? postsCount.toInt() : totalPosts.value;
    totalLikes.value =
        (likesCount is num) ? likesCount.toInt() : totalLikes.value;
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
