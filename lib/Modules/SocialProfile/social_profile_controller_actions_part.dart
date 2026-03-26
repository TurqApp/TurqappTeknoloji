part of 'social_profile_controller.dart';

extension SocialProfileControllerActionsPart on SocialProfileController {
  Future<void> _performGetSocialMediaLinks() async {
    final hadFreshCache = await _socialLinksRepository.hasFreshCacheEntry(
      userID,
    );
    var list = await _socialLinksRepository.getLinks(
      userID,
      preferCache: true,
      forceRefresh: false,
    );
    if (hadFreshCache && list.isEmpty) {
      list = await _socialLinksRepository.getLinks(
        userID,
        preferCache: false,
        forceRefresh: true,
      );
    }
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
                        maybeFindSocialMediaController()?.getData(
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

  Future<void> _performToggleFollowStatus() async {
    if (followLoading.value) return;
    final currentUid = CurrentUserService.instance.effectiveUserId;
    if (currentUid.isEmpty || currentUid == userID) return;
    final bool wasFollowing = takipEdiyorum.value;
    followLoading.value = true;
    try {
      if (!wasFollowing) {
        final alreadyFollowing = await ensureFollowRepository().isFollowing(
          userID,
          currentUid: currentUid,
          preferCache: false,
        );
        if (alreadyFollowing) {
          takipEdiyorum.value = true;
          _followCheckCache['$currentUid:$userID'] =
              _SocialFollowCheckCacheEntry(
            isFollowing: true,
            cachedAt: DateTime.now(),
          );
          return;
        }
      }

      takipEdiyorum.value = !wasFollowing;
      final outcome = await FollowService.toggleFollowFromLocalState(
        userID,
        assumedFollowing: wasFollowing,
      );
      takipEdiyorum.value = outcome.nowFollowing;
      if (currentUid.isNotEmpty) {
        _followCheckCache['$currentUid:$userID'] = _SocialFollowCheckCacheEntry(
          isFollowing: outcome.nowFollowing,
          cachedAt: DateTime.now(),
        );
      }

      if (outcome.nowFollowing && !wasFollowing) {
        totalFollower.value++;
        postNotificationsEnabled.value = false;
        NotificationService.instance.sendNotification(
          token: token.value,
          title: CurrentUserService.instance.nickname,
          body: "seni takip etmeye başladı",
          docID: userID,
          type: "User",
        );
      } else if (!outcome.nowFollowing && wasFollowing) {
        totalFollower.value--;
        postNotificationsEnabled.value = false;
        try {
          await _postNotificationSubscriberRef(userID, currentUid).delete();
        } catch (e) {
          print('SocialProfile unfollow notification cleanup error: $e');
        }
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

  Future<void> _performTogglePostNotifications() async {
    if (postNotificationsLoading.value) return;
    final currentUid = CurrentUserService.instance.effectiveUserId;
    if (currentUid.isEmpty ||
        currentUid == userID ||
        takipEdiyorum.value == false) {
      return;
    }

    final enable = postNotificationsEnabled.value == false;
    postNotificationsLoading.value = true;
    try {
      if (enable) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await _postNotificationSubscriberRef(userID, currentUid).set(
          {
            'subscriberId': currentUid,
            'authorId': userID,
            'createdAt': now,
            'updatedAt': now,
          },
          SetOptions(merge: true),
        );
        postNotificationsEnabled.value = true;
        AppSnackbar(
          'Bildirimler açıldı',
          '@${nickname.value} yeni gönderi paylaştığında bildirim alacaksın',
        );
      } else {
        await _postNotificationSubscriberRef(userID, currentUid).delete();
        postNotificationsEnabled.value = false;
        AppSnackbar(
          'Bildirimler kapatıldı',
          '@${nickname.value} için gönderi bildirimi kapatıldı',
        );
      }
    } catch (e) {
      print('SocialProfile togglePostNotifications error: $e');
    } finally {
      postNotificationsLoading.value = false;
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
}
