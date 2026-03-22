part of 'social_profile_controller.dart';

extension SocialProfileControllerProfilePart on SocialProfileController {
  String _performResolveNickname(
    Map<String, dynamic> raw,
    Map<String, dynamic> profile,
  ) {
    final nickname =
        (raw["nickname"] ?? profile["nickname"] ?? "").toString().trim();
    final username =
        (raw["username"] ?? profile["username"] ?? "").toString().trim();
    final displayName =
        (raw["displayName"] ?? profile["displayName"] ?? "").toString().trim();
    if (nickname.isNotEmpty) return nickname;
    if (username.isNotEmpty) return username;
    return displayName;
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
      final cached = SocialProfileController._counterCache[userID];
      if (cached != null &&
          DateTime.now().difference(cached.cachedAt) <=
              SocialProfileController._counterCacheTtl) {
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
      SocialProfileController._counterCache[userID] = _SocialCounterCacheEntry(
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
    } catch (e) {
      print('SocialProfileController hydrate reshares error: $e');
    }
  }

  Future<void> _performIsFollowingCheck() async {
    final currentUid = CurrentUserService.instance.effectiveUserId;
    if (currentUid.isEmpty) return;
    _pruneCaches();
    final cacheKey = '$currentUid:$userID';
    final cached = SocialProfileController._followCheckCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            SocialProfileController._followCheckCacheTtl) {
      takipEdiyorum.value = cached.isFollowing;
      complatedCheck.value = true;
      return;
    }
    final isFollowing = await FollowRepository.ensure().isFollowing(
      userID,
      currentUid: currentUid,
      preferCache: true,
    );
    takipEdiyorum.value = isFollowing;
    complatedCheck.value = true;
    SocialProfileController._followCheckCache[cacheKey] =
        _SocialFollowCheckCacheEntry(
      isFollowing: isFollowing,
      cachedAt: DateTime.now(),
    );
  }

  Future<void> _performGetSocialMediaLinks() async {
    final list = await _socialLinksRepository.getLinks(
      userID,
      preferCache: true,
      forceRefresh: false,
    );
    socialMediaList.value = list;
  }

  Future<void> _performShowSocialMediaLinkDelete(String docID) async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'social_links.remove_title'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratBold",
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'social_links.remove_message'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'common.cancel'.tr,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Get.back();
                      await _socialLinksRepository.deleteLink(userID, docID);

                      unawaited(
                        SocialMediaController.maybeFind()?.getData(
                              silent: true,
                              forceRefresh: true,
                            ) ??
                            Future.value(),
                      );
                    },
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Text(
                        'common.remove'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
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

  Future<void> _performToggleFollowStatus() async {
    if (followLoading.value) return;
    final bool wasFollowing = takipEdiyorum.value;
    takipEdiyorum.value = !wasFollowing;
    followLoading.value = true;
    try {
      final outcome = await FollowService.toggleFollow(userID);
      takipEdiyorum.value = outcome.nowFollowing;
      final currentUid = CurrentUserService.instance.effectiveUserId;
      if (currentUid.isNotEmpty) {
        SocialProfileController._followCheckCache['$currentUid:$userID'] =
            _SocialFollowCheckCacheEntry(
          isFollowing: outcome.nowFollowing,
          cachedAt: DateTime.now(),
        );
      }

      if (outcome.nowFollowing && !wasFollowing) {
        totalFollower.value++;
        NotificationService.instance.sendNotification(
          token: token.value,
          title: CurrentUserService.instance.nickname,
          body: "seni takip etmeye başladı",
          docID: userID,
          type: "User",
        );
      } else if (!outcome.nowFollowing && wasFollowing) {
        totalFollower.value--;
      }

      if (outcome.limitReached) {
        AppSnackbar('following.limit_title'.tr, 'following.limit_body'.tr);
      }
    } catch (e) {
      takipEdiyorum.value = wasFollowing;
      print("Bir hata oluştu: $e");
    } finally {
      followLoading.value = false;
    }
  }

  Future<void> _performBlock() async {
    await noYesAlert(
      title: 'common.block'.tr,
      message: 'social_profile.block_confirm_body'
          .trParams({'nickname': nickname.value}),
      cancelText: 'common.cancel'.tr,
      yesText: 'common.block'.tr,
      onYesPressed: () async {
        final currentUid = CurrentUserService.instance.effectiveUserId;
        await _userSubcollectionRepository.upsertEntry(
          currentUid,
          subcollection: 'blockedUsers',
          docId: userID,
          data: {
            "userID": userID,
            "updatedDate": DateTime.now().millisecondsSinceEpoch,
          },
        );

        await FollowService.deleteRelationPair(
          userID,
          currentUid: currentUid,
        );
        await FollowService.deleteRelationPair(
          currentUid,
          currentUid: userID,
        );

        CurrentUserService.instance.forceRefresh();
        getUserData();
        isFollowingCheck();
      },
    );
  }

  Future<void> _performUnblock() async {
    await noYesAlert(
      title: 'blocked_users.unblock_confirm_title'.tr,
      message: 'blocked_users.unblock_confirm_body'
          .trParams({'nickname': nickname.value}),
      cancelText: 'common.cancel'.tr,
      yesText: 'blocked_users.unblock'.tr,
      onYesPressed: () async {
        final currentUid = CurrentUserService.instance.effectiveUserId;
        await _userSubcollectionRepository.deleteEntry(
          currentUid,
          subcollection: 'blockedUsers',
          docId: userID,
        );
        CurrentUserService.instance.forceRefresh();
        getUserData();
        isFollowingCheck();
      },
    );
  }

  Future<void> _performGetUserStoryUserModelAndPrint(String userId) async {
    final stories = await _storyRepository.getStoriesForUser(
      userId,
      preferCache: true,
    );

    if (stories.isEmpty) {
      print("Kullanıcıya ait hiç hikaye yok.");
      return;
    }

    final summary = await _userSummaryResolver.resolve(
      userId,
      preferCache: true,
    );
    if (summary == null) {
      print("Kullanıcı bulunamadı.");
      return;
    }
    final raw = await _userRepository.getUserRaw(
      userId,
      preferCache: true,
      cacheOnly: true,
    );
    final fullNameSource = raw ?? const <String, dynamic>{};
    final userModel = StoryUserModel(
      nickname: summary.nickname,
      avatarUrl: summary.avatarUrl,
      fullName:
          "${fullNameSource['firstName'] ?? ""} ${fullNameSource['lastName'] ?? ""}"
              .trim(),
      userID: userId,
      stories: stories,
    );

    print("Kullanıcı StoryUserModel: $userModel");
    storyUserModel = userModel;
    print(
      "Nickname: ${userModel.nickname}, Story Sayısı: ${userModel.stories.length}",
    );
  }

  void _performPruneCaches() {
    final now = DateTime.now();
    bool isStale(DateTime t) =>
        now.difference(t) > SocialProfileController._cacheStaleRetention;
    SocialProfileController._followCheckCache
        .removeWhere((_, v) => isStale(v.cachedAt));
    SocialProfileController._counterCache
        .removeWhere((_, v) => isStale(v.cachedAt));
    _trimMap(SocialProfileController._followCheckCache, (v) => v.cachedAt);
    _trimMap(SocialProfileController._counterCache, (v) => v.cachedAt);
  }

  void _performTrimMap<T>(
    Map<String, T> map,
    DateTime Function(T value) cachedAt,
  ) {
    if (map.length <= SocialProfileController._maxCacheEntries) return;
    final entries = map.entries.toList()
      ..sort((a, b) => cachedAt(a.value).compareTo(cachedAt(b.value)));
    final removeCount = map.length - SocialProfileController._maxCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      map.remove(entries[i].key);
    }
  }
}
