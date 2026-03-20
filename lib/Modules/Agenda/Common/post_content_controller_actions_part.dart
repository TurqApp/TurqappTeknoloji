part of 'post_content_controller.dart';

extension PostContentControllerActionsPart on PostContentController {
  Future<void> getGizleArsivSikayetEdildi() async {
    gizlendi.value = model.gizlendi;
    arsiv.value = model.arsiv;
    silindi.value = model.deletedPost;
  }

  Future<void> gizle() async {
    final shortController = shortsController;
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].gizlendi = true;

    final exploreController = Get.find<ExploreController>();

    final index3 = exploreController.explorePosts.indexOf(model);
    if (index3 >= 0) exploreController.explorePosts[index3].gizlendi = true;

    final index4 = exploreController.explorePhotos.indexOf(model);
    if (index4 >= 0) exploreController.explorePhotos[index4].gizlendi = true;

    final index5 = exploreController.exploreVideos.indexOf(model);
    if (index5 >= 0) exploreController.exploreVideos[index5].gizlendi = true;

    final store8 = Get.find<AgendaController>();
    final index8 = store8.agendaList.indexOf(model);
    if (index8 >= 0) store8.agendaList[index8].gizlendi = true;

    final store9 = Get.find<ProfileController>();
    final index9 = store9.allPosts.indexOf(model);
    if (index9 >= 0) store9.allPosts[index9].gizlendi = true;

    final store10 = Get.find<ProfileController>();
    final index10 = store10.allPosts.indexOf(model);
    if (index10 >= 0) store10.allPosts[index10].gizlendi = true;

    gizlendi.value = true;
  }

  Future<void> gizlemeyiGeriAl() async {
    final shortController = shortsController;
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].gizlendi = false;

    final exploreController = Get.find<ExploreController>();

    final index3 = exploreController.explorePosts.indexOf(model);
    if (index3 >= 0) exploreController.explorePosts[index3].gizlendi = false;

    final index4 = exploreController.explorePhotos.indexOf(model);
    if (index4 >= 0) exploreController.explorePhotos[index4].gizlendi = false;

    final index5 = exploreController.exploreVideos.indexOf(model);
    if (index5 >= 0) exploreController.exploreVideos[index5].gizlendi = false;

    final store8 = Get.find<AgendaController>();
    final index8 = store8.agendaList.indexOf(model);
    if (index8 >= 0) store8.agendaList[index8].gizlendi = false;

    final store9 = Get.find<ProfileController>();
    final index9 = store9.allPosts.indexOf(model);
    if (index9 >= 0) store9.allPosts[index9].gizlendi = false;

    final store10 = Get.find<ProfileController>();
    final index10 = store10.allPosts.indexOf(model);
    if (index10 >= 0) store10.allPosts[index10].gizlendi = false;

    gizlendi.value = false;
  }

  Future<void> arsivle() async {
    await _postRepository.setArchived(model, true);

    // Tüm ilgili store ve listeleri güncelle
    final shortController = shortsController;
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].arsiv = true;
    final exploreController = Get.find<ExploreController>();

    final index3 = exploreController.explorePosts.indexOf(model);
    if (index3 >= 0) exploreController.explorePosts[index3].arsiv = true;

    final index4 = exploreController.explorePhotos.indexOf(model);
    if (index4 >= 0) exploreController.explorePhotos[index4].arsiv = true;

    final index5 = exploreController.exploreVideos.indexOf(model);
    if (index5 >= 0) exploreController.exploreVideos[index5].arsiv = true;

    final store8 = Get.find<AgendaController>();
    final index8 = store8.agendaList.indexOf(model);
    if (index8 >= 0) store8.agendaList[index8].arsiv = true;

    final store9 = Get.find<ProfileController>();
    final index9 = store9.allPosts.indexOf(model);
    if (index9 >= 0) store9.allPosts[index9].arsiv = false;

    final store10 = Get.find<ProfileController>();
    final index10 = store10.allPosts.indexOf(model);
    if (index10 >= 0) store10.allPosts[index10].arsiv = false;

    arsiv.value = true;
  }

  Future<void> arsivdenCikart() async {
    await _postRepository.setArchived(model, false);

    final shortController = shortsController;
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].arsiv = false;

    final exploreController = Get.find<ExploreController>();
    final index3 = exploreController.explorePosts.indexOf(model);
    if (index3 >= 0) exploreController.explorePosts[index3].arsiv = false;

    final index4 = exploreController.explorePhotos.indexOf(model);
    if (index4 >= 0) exploreController.explorePhotos[index4].arsiv = false;

    final index5 = exploreController.exploreVideos.indexOf(model);
    if (index5 >= 0) exploreController.exploreVideos[index5].arsiv = false;

    final store8 = Get.find<AgendaController>();
    final index8 = store8.agendaList.indexOf(model);
    if (index8 >= 0) store8.agendaList[index8].arsiv = false;

    final store9 = Get.find<ProfileController>();
    final index9 = store9.allPosts.indexOf(model);
    if (index9 >= 0) store9.allPosts[index9].arsiv = false;

    final store10 = Get.find<ProfileController>();
    final index10 = store10.allPosts.indexOf(model);
    if (index10 >= 0) store10.allPosts[index10].arsiv = false;

    if (Get.isRegistered<ArchiveController>()) {
      final store11 = Get.find<ArchiveController>();
      final index11 = store11.list.indexOf(model);
      if (index11 >= 0) store11.list.removeAt(index11);
    }

    arsiv.value = false;
  }

  Future<void> sil() async {
    await PostDeleteService.instance.softDelete(model);
    silindi.value = true; // UI overlay

    // Yumuşak fade-out
    Future.delayed(const Duration(milliseconds: 2600), () {
      silindiOpacity.value = 0.0;
    });

    // 3 sn sonra overlay'i kaldır ve ana listeden çıkar
    Future.delayed(const Duration(seconds: 3), () {
      if (Get.isRegistered<AgendaController>()) {
        final agenda = Get.find<AgendaController>();
        final idx = agenda.agendaList.indexWhere((e) => e.docID == model.docID);
        if (idx != -1) {
          agenda.agendaList.removeAt(idx);
          agenda.agendaList.refresh();
        }
      }
    });
  }

  Future<void> reshare() async {
    final targetPostId = reshareTargetPostId;
    final bool wasReshared = yenidenPaylasildiMi.value;

    try {
      final status = targetPostId == model.docID
          ? await _postRepository.toggleReshare(model)
          : await _interactionService.toggleReshare(targetPostId);

      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (status) {
        yenidenPaylasildiMi.value = true;
        if (uid != null && !reSharedUsers.contains(uid)) {
          reSharedUsers.add(uid);
          reShareUserUserID.value = uid;
          reShareUserNickname.value = 'Sen';
          agendaController.myReshares[targetPostId] =
              DateTime.now().millisecondsSinceEpoch;
        }
        try {
          Get.find<ProfileController>().getResharesSingle();
        } catch (_) {}
        await onReshareAdded(uid, targetPostId: targetPostId);
      } else {
        yenidenPaylasildiMi.value = false;
        if (uid != null) {
          reSharedUsers.remove(uid);
          agendaController.myReshares.remove(targetPostId);
        }
        reShareUserUserID.value = '';
        reShareUserNickname.value = '';
        try {
          Get.find<ProfileController>().removeReshare(targetPostId);
        } catch (_) {}
        await onReshareRemoved(uid, targetPostId: targetPostId);
      }
    } catch (e) {
      yenidenPaylasildiMi.value = wasReshared;
      AppSnackbar('common.error'.tr, 'post.reshare_failed'.tr);
    }
  }

  Future<void> followCheck() async {
    if (model.userID != FirebaseAuth.instance.currentUser!.uid) {
      if (agendaController.followingIDs.contains(model.userID)) {
        isFollowing.value = true;
        return;
      }
      final docExists = await FollowRepository.ensure().isFollowing(
        model.userID,
        currentUid: FirebaseAuth.instance.currentUser!.uid,
        preferCache: true,
      );
      isFollowing.value = docExists;
      if (docExists) {
        agendaController.followingIDs.add(model.userID);
      }
    }
  }

  Future<void> getUserData(String userID) async {
    final postLevelNickname = model.authorNickname.trim();
    final postLevelDisplayName = model.authorDisplayName.trim();
    final postLevelAvatarFallback = model.authorAvatarUrl.trim();
    final hasPostLevelIdentity = postLevelNickname.isNotEmpty &&
        postLevelDisplayName.isNotEmpty &&
        postLevelAvatarFallback.isNotEmpty;

    void applyProfile({
      required String nick,
      required String uname,
      required String image,
      required String pushToken,
      required String name,
    }) {
      final rawImage = image.toString().trim();
      final shouldUsePostFallback = postLevelAvatarFallback.isNotEmpty &&
          (rawImage.isEmpty || rawImage == kDefaultAvatarUrl);
      final normalizedImage = shouldUsePostFallback
          ? postLevelAvatarFallback
          : (rawImage.isEmpty ? kDefaultAvatarUrl : rawImage);
      final effectiveNick = postLevelNickname.isNotEmpty ? postLevelNickname : nick;
      final effectiveName = postLevelDisplayName.isNotEmpty ? postLevelDisplayName : name;
      nickname.value = effectiveNick;
      username.value = uname.isNotEmpty ? uname : effectiveNick;
      avatarUrl.value = normalizedImage;
      token.value = pushToken;
      fullName.value = effectiveName;
    }

    void cacheProfile({
      required String uid,
      required String nick,
      required String uname,
      required String image,
      required String pushToken,
      required String name,
    }) {
      PostContentController._userProfileCache[uid] = _UserProfileCacheEntry(
        nickname: nick,
        username: uname,
        avatarUrl: image,
        token: pushToken,
        fullName: name,
        updatedAt: DateTime.now(),
      );
    }

    void bindCurrentUserStream() {
      _currentUserStreamSub?.cancel();
      _currentUserStreamSub = userService.userStream.listen((user) {
        if (user == null || user.userID != userID) return;
        final currentUserDisplayName =
            user.fullName.trim().isNotEmpty ? user.fullName : user.nickname;
        final image = userService.avatarUrl;
        applyProfile(
          nick: user.nickname,
          uname: user.nickname,
          image: image,
          pushToken: user.token,
          name: currentUserDisplayName,
        );
        cacheProfile(
          uid: userID,
          nick: user.nickname,
          uname: user.nickname,
          image: image,
          pushToken: user.token,
          name: currentUserDisplayName,
        );
      });
    }

    // Current user posts should stay bound to current-user stream so avatar/
    // nickname changes are reflected immediately in feed cards.
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == userID) {
      if (userService.currentUser != null) {
        final user = userService.currentUser!;
        final currentUserDisplayName =
            user.fullName.trim().isNotEmpty ? user.fullName : user.nickname;
        final image = userService.avatarUrl;
        applyProfile(
          nick: user.nickname,
          uname: user.nickname,
          image: image,
          pushToken: user.token,
          name: currentUserDisplayName,
        );
        cacheProfile(
          uid: userID,
          nick: user.nickname,
          uname: user.nickname,
          image: image,
          pushToken: user.token,
          name: currentUserDisplayName,
        );
        bindCurrentUserStream();
        return;
      }
      bindCurrentUserStream();
    }
    if (currentUserId != userID) {
      _currentUserStreamSub?.cancel();
      _currentUserStreamSub = null;
    }

    if (hasPostLevelIdentity) {
      applyProfile(
        nick: postLevelNickname,
        uname: postLevelNickname,
        image: postLevelAvatarFallback,
        pushToken: '',
        name: postLevelDisplayName,
      );
      return;
    }

    // 0) Aynı kullanıcı için hafızadaki cache tazeyse, ağa gitmeden çık.
    final cachedProfile = PostContentController._userProfileCache[userID];
    if (cachedProfile != null &&
        DateTime.now().difference(cachedProfile.updatedAt) <
            PostContentController._userProfileCacheTtl) {
      applyProfile(
        nick: cachedProfile.nickname,
        uname: cachedProfile.username,
        image: cachedProfile.avatarUrl,
        pushToken: cachedProfile.token,
        name: cachedProfile.fullName,
      );
      return;
    }

    final userSummaryResolver = UserSummaryResolver.ensure();
    final warmProfile = userSummaryResolver.peek(userID, allowStale: true);
    if (warmProfile != null) {
      applyProfile(
        nick: warmProfile.nickname,
        uname: warmProfile.username.isNotEmpty
            ? warmProfile.username
            : warmProfile.nickname,
        image: warmProfile.avatarUrl,
        pushToken: warmProfile.token,
        name: warmProfile.preferredName,
      );
      cacheProfile(
        uid: userID,
        nick: warmProfile.nickname,
        uname: warmProfile.username.isNotEmpty
            ? warmProfile.username
            : warmProfile.nickname,
        image: warmProfile.avatarUrl,
        pushToken: warmProfile.token,
        name: warmProfile.preferredName,
      );
      return;
    }

    try {
      final summary = await userSummaryResolver.resolve(
        userID,
        preferCache: true,
        cacheOnly: false,
      );
      if (summary != null) {
        applyProfile(
          nick: summary.nickname,
          uname:
              summary.username.isNotEmpty ? summary.username : summary.nickname,
          image: summary.avatarUrl,
          pushToken: summary.token,
          name: summary.preferredName,
        );
        cacheProfile(
          uid: userID,
          nick: summary.nickname,
          uname:
              summary.username.isNotEmpty ? summary.username : summary.nickname,
          image: summary.avatarUrl,
          pushToken: summary.token,
          name: summary.preferredName,
        );
      }
    } catch (_) {}
  }

  Future<void> goToPreview() async {
    //flood listing
  }

  Future<void> saveSeeing() async {
    try {
      await _interactionService.recordView(model.docID);
    } catch (_) {}
  }

  Future<void> getReSharedUsers(String docID) async {
    final cached = PostContentController._reshareUsersCache[docID];
    if (cached != null &&
        DateTime.now().difference(cached.updatedAt) <
            PostContentController._reshareUsersCacheTtl) {
      reSharedUsers.value = cached.userIds;
      reShareUserUserID.value = cached.displayUserId;
      reShareUserNickname.value = cached.displayNickname;
      return;
    }

    final reshareEntries = await _postRepository.fetchAllReshareEntries(
      docID,
      limit: 200,
    );
    final entries =
        reshareEntries.map((e) => MapEntry(e.userId, e.timeStamp)).toList();
    // ID listesi
    final list = entries.map((e) => e.key).toList();
    reSharedUsers.value = list;

    // Kimi göstereceğiz? Önce ben, sonra takip ettiklerimden en günceli
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me != null && list.contains(me)) {
      reShareUserUserID.value = me;
      reShareUserNickname.value = 'Sen';
      PostContentController._reshareUsersCache[docID] = _ReshareUsersCacheEntry(
        updatedAt: DateTime.now(),
        userIds: List<String>.from(list),
        displayUserId: me,
        displayNickname: 'Sen',
      );
      return;
    }

    // Takip ettiklerimden biri var mı?
    try {
      final following = agendaController.followingIDs;
      // Takip edilenler içinden en yeni timeStamp’e sahip olanı seç
      final candidates = entries
          .where((e) => following.contains(e.key))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (candidates.isNotEmpty) {
        final match = candidates.first.key;
        reShareUserUserID.value = match;
        final cached = ReshareHelper.getCachedNickname(match);
        if (cached != null) {
          reShareUserNickname.value = cached;
        } else {
          final nick = await ReshareHelper.getUserNickname(match);
          reShareUserNickname.value = nick;
        }
        PostContentController._reshareUsersCache[docID] =
            _ReshareUsersCacheEntry(
          updatedAt: DateTime.now(),
          userIds: List<String>.from(list),
          displayUserId: match,
          displayNickname: reShareUserNickname.value,
        );
        return;
      }
    } catch (_) {}

    // Kimse yoksa temizle
    reShareUserUserID.value = '';
    reShareUserNickname.value = '';
    PostContentController._reshareUsersCache[docID] = _ReshareUsersCacheEntry(
      updatedAt: DateTime.now(),
      userIds: List<String>.from(list),
      displayUserId: '',
      displayNickname: '',
    );
  }

  Future<void> like() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final bool wasLiked = uid != null && likes.contains(uid);

    try {
      await _postRepository.toggleLike(model);
    } catch (e) {
      if (uid != null) {
        if (wasLiked) {
          if (!likes.contains(uid)) likes.add(uid);
        } else {
          likes.remove(uid);
        }
      }
      AppSnackbar('common.error'.tr, 'post.like_failed'.tr);
    }
  }

  Future<void> save() async {
    final bool wasSaved = saved.value;

    try {
      await _postRepository.toggleSave(model);
    } catch (e) {
      saved.value = wasSaved;
      AppSnackbar('common.error'.tr, 'post.save_failed'.tr);
    }
  }

  Future<void> showPostCommentsBottomSheet({VoidCallback? onClosed}) async {
    await Get.bottomSheet(
      SizedBox(
        height: Get.height * 0.55, // Ekranın %95'i kadar yükseklik
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: PostComments(
            postID: model.docID,
            userID: model.userID,
            collection: 'Posts',
            onCommentCountChange: (increment) async {
              await updateCommentCount(increment: increment);
            },
          ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true, // Sürükleyerek kapatma için
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white, // Alt barda arka plan rengi
      barrierColor: Colors.black54, // Gri karartma rengi
    ).then((v) {
      if (onClosed != null) onClosed();
    });
  }

  Future<void> followUser() async {
    if (model.userID == FirebaseAuth.instance.currentUser!.uid) return;
    await onlyFollowUserOneTime();
  }

  Future<void> onlyFollowUserOneTime() async {
    try {
      if (followLoading.value) return;
      final currentUid = FirebaseAuth.instance.currentUser!.uid;
      final alreadyFollowing = await FollowRepository.ensure().isFollowing(
        model.userID,
        currentUid: currentUid,
        preferCache: true,
      );
      if (alreadyFollowing) {
        isFollowing.value = true;
        return;
      }

      followLoading.value = true;
      final outcome = await FollowService.toggleFollow(model.userID);
      if (outcome.nowFollowing) {
        isFollowing.value = true;
      }
      if (outcome.limitReached) {
        AppSnackbar('following.limit_title'.tr, 'following.limit_body'.tr);
      }
    } catch (e) {
      print('Bir hata oluştu: $e');
    } finally {
      followLoading.value = false;
    }
  }

  Future<void> sendPost() async {
    Get.bottomSheet(Container(
      height: Get.height / 1.5,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(12), topLeft: Radius.circular(12))),
      child: ShareGrid(postID: model.docID, postType: "Post"),
    ));
  }

  Future<void> sendAdminPushForPost() async {
    if (!canSendAdminPush) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final pushCopy = _buildPostPushCopy();
    final title = pushCopy.title;
    final body = pushCopy.body;
    final imageUrl = _pushPreviewImageUrl();

    try {
      final written = await _adminPushRepository.sendPostPush(
        postId: model.docID,
        title: title,
        body: body,
        imageUrl: imageUrl,
      );
      try {
        await _adminPushRepository.addPostReport(
          senderUid: currentUid,
          title: title,
          body: body,
          targetCount: written,
          postId: model.docID,
          imageUrl: imageUrl,
        );
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
      }
      AppSnackbar(
        'admin_push.queue_title'.tr,
        'admin_push.queue_body_count'.trParams({'count': '$written'}),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        AppSnackbar('admin_push.queue_title'.tr, 'admin_push.queue_body'.tr);
        return;
      }
      AppSnackbar('common.error'.tr, 'post.push_failed'.tr);
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.push_failed'.tr);
    }
  }

  // Dinamik sayaç güncelleme fonksiyonları
  Future<void> updateCommentCount({bool increment = true}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (increment) {
      commentCount.value++;
      // Yorum yapıldığında kullanıcıyı comments listesine ekle
      if (uid != null && !comments.contains(uid)) {
        comments.add(uid);
      }
    } else if (commentCount.value > 0) {
      commentCount.value--;
      // Yorum silindiğinde kullanıcıyı listeden çıkar (eğer başka yorumu yoksa)
      if (uid != null) {
        // Real-time listener zaten kontrol ediyor, ek işlem gerekmiyor
        // Çünkü _bindCommentsListener kullanıcının yorumlarını dinliyor
      }
    }
  }

  Future<void> updateStatsCount() async {
    try {
      await countManager.updateStatsCount(model.docID, by: 1);
      final newStats = PostStats(
        commentCount: model.stats.commentCount,
        likeCount: model.stats.likeCount,
        reportedCount: model.stats.reportedCount,
        retryCount: model.stats.retryCount,
        savedCount: model.stats.savedCount,
        statsCount: statsCount.value,
      );
      model.stats = newStats;
      currentModel.value = model;
    } catch (e) {
      print('Stats count update error: $e');
    }
  }
}

class _UserProfileCacheEntry {
  final String nickname;
  final String username;
  final String avatarUrl;
  final String token;
  final String fullName;
  final DateTime updatedAt;

  const _UserProfileCacheEntry({
    required this.nickname,
    required this.username,
    required this.avatarUrl,
    required this.token,
    required this.fullName,
    required this.updatedAt,
  });
}

class _ReshareUsersCacheEntry {
  final DateTime updatedAt;
  final List<String> userIds;
  final String displayUserId;
  final String displayNickname;

  const _ReshareUsersCacheEntry({
    required this.updatedAt,
    required this.userIds,
    required this.displayUserId,
    required this.displayNickname,
  });
}
