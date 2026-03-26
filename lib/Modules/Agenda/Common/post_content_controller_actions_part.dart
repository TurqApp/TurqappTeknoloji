part of 'post_content_controller.dart';

extension PostContentControllerActionsPart on PostContentController {
  ExploreController? get _exploreControllerOrNull =>
      ExploreController.maybeFind();

  ProfileController? get _profileControllerOrNull =>
      ProfileController.maybeFind();

  ArchiveController? get _archiveControllerOrNull =>
      ArchiveController.maybeFind();

  Future<void> getGizleArsivSikayetEdildi() async {
    gizlendi.value = model.gizlendi;
    arsiv.value = model.arsiv;
    silindi.value = model.deletedPost;
  }

  Future<void> gizle() async {
    final shortController = shortsController;
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].gizlendi = true;

    final exploreController = _exploreControllerOrNull;

    if (exploreController != null) {
      final index3 = exploreController.explorePosts.indexOf(model);
      if (index3 >= 0) {
        exploreController.explorePosts[index3].gizlendi = true;
      }

      final index4 = exploreController.explorePhotos.indexOf(model);
      if (index4 >= 0) {
        exploreController.explorePhotos[index4].gizlendi = true;
      }

      final index5 = exploreController.exploreVideos.indexOf(model);
      if (index5 >= 0) {
        exploreController.exploreVideos[index5].gizlendi = true;
      }
    }

    final index8 = agendaController.agendaList.indexOf(model);
    if (index8 >= 0) agendaController.agendaList[index8].gizlendi = true;

    final profileController = _profileControllerOrNull;
    if (profileController != null) {
      final index9 = profileController.allPosts.indexOf(model);
      if (index9 >= 0) profileController.allPosts[index9].gizlendi = true;
    }

    gizlendi.value = true;
  }

  Future<void> gizlemeyiGeriAl() async {
    final shortController = shortsController;
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].gizlendi = false;

    final exploreController = _exploreControllerOrNull;

    if (exploreController != null) {
      final index3 = exploreController.explorePosts.indexOf(model);
      if (index3 >= 0) {
        exploreController.explorePosts[index3].gizlendi = false;
      }

      final index4 = exploreController.explorePhotos.indexOf(model);
      if (index4 >= 0) {
        exploreController.explorePhotos[index4].gizlendi = false;
      }

      final index5 = exploreController.exploreVideos.indexOf(model);
      if (index5 >= 0) {
        exploreController.exploreVideos[index5].gizlendi = false;
      }
    }

    final index8 = agendaController.agendaList.indexOf(model);
    if (index8 >= 0) agendaController.agendaList[index8].gizlendi = false;

    final profileController = _profileControllerOrNull;
    if (profileController != null) {
      final index9 = profileController.allPosts.indexOf(model);
      if (index9 >= 0) profileController.allPosts[index9].gizlendi = false;
    }

    gizlendi.value = false;
  }

  Future<void> arsivle() async {
    await _postRepository.setArchived(model, true);

    // Tüm ilgili store ve listeleri güncelle
    final shortController = shortsController;
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].arsiv = true;
    final exploreController = _exploreControllerOrNull;

    if (exploreController != null) {
      final index3 = exploreController.explorePosts.indexOf(model);
      if (index3 >= 0) exploreController.explorePosts[index3].arsiv = true;

      final index4 = exploreController.explorePhotos.indexOf(model);
      if (index4 >= 0) exploreController.explorePhotos[index4].arsiv = true;

      final index5 = exploreController.exploreVideos.indexOf(model);
      if (index5 >= 0) exploreController.exploreVideos[index5].arsiv = true;
    }

    final index8 = agendaController.agendaList.indexOf(model);
    if (index8 >= 0) agendaController.agendaList[index8].arsiv = true;

    final profileController = _profileControllerOrNull;
    if (profileController != null) {
      final index9 = profileController.allPosts.indexOf(model);
      if (index9 >= 0) profileController.allPosts[index9].arsiv = false;
    }

    arsiv.value = true;
  }

  Future<void> arsivdenCikart() async {
    await _postRepository.setArchived(model, false);

    final shortController = shortsController;
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].arsiv = false;

    final exploreController = _exploreControllerOrNull;
    if (exploreController != null) {
      final index3 = exploreController.explorePosts.indexOf(model);
      if (index3 >= 0) exploreController.explorePosts[index3].arsiv = false;

      final index4 = exploreController.explorePhotos.indexOf(model);
      if (index4 >= 0) exploreController.explorePhotos[index4].arsiv = false;

      final index5 = exploreController.exploreVideos.indexOf(model);
      if (index5 >= 0) exploreController.exploreVideos[index5].arsiv = false;
    }

    final index8 = agendaController.agendaList.indexOf(model);
    if (index8 >= 0) agendaController.agendaList[index8].arsiv = false;

    final profileController = _profileControllerOrNull;
    if (profileController != null) {
      final index9 = profileController.allPosts.indexOf(model);
      if (index9 >= 0) profileController.allPosts[index9].arsiv = false;
    }

    final archiveController = _archiveControllerOrNull;
    if (archiveController != null) {
      archiveController.removeArchivedPost(model.docID);
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
      final idx = agendaController.agendaList.indexWhere(
        (e) => e.docID == model.docID,
      );
      if (idx != -1) {
        agendaController.agendaList.removeAt(idx);
        agendaController.agendaList.refresh();
      }
    });
  }

  Future<void> reshare() async {
    final targetPostId = reshareTargetPostId;
    final isDirectTarget = targetPostId == model.docID;
    final bool wasReshared = yenidenPaylasildiMi.value;

    try {
      final status = isDirectTarget
          ? await _postRepository.toggleReshare(model)
          : await _interactionService.toggleReshare(targetPostId);

      final uid = _currentUid;
      if (!isDirectTarget) {
        _syncIndirectReshareCountLocally(
          targetPostId: targetPostId,
          nowReshared: status,
          wasReshared: wasReshared,
        );
      }

      if (status) {
        yenidenPaylasildiMi.value = true;
        if (uid.isNotEmpty && !reSharedUsers.contains(uid)) {
          reSharedUsers.add(uid);
          reShareUserUserID.value = uid;
          reShareUserNickname.value = 'Sen';
          agendaController.myReshares[targetPostId] =
              DateTime.now().millisecondsSinceEpoch;
        }
        try {
          _profileControllerOrNull?.getResharesSingle();
        } catch (_) {}
        await onReshareAdded(uid, targetPostId: targetPostId);
      } else {
        yenidenPaylasildiMi.value = false;
        if (uid.isNotEmpty) {
          reSharedUsers.remove(uid);
          agendaController.myReshares.remove(targetPostId);
        }
        reShareUserUserID.value = '';
        reShareUserNickname.value = '';
        try {
          _profileControllerOrNull?.removeReshare(targetPostId);
        } catch (_) {}
        await onReshareRemoved(uid, targetPostId: targetPostId);
      }
    } catch (e) {
      yenidenPaylasildiMi.value = wasReshared;
      AppSnackbar('common.error'.tr, 'post.reshare_failed'.tr);
    }
  }

  void _syncIndirectReshareCountLocally({
    required String targetPostId,
    required bool nowReshared,
    required bool wasReshared,
  }) {
    if (targetPostId.isEmpty || nowReshared == wasReshared) return;
    final delta = nowReshared ? 1 : -1;
    final next = (countManager.getRetryCount(targetPostId).value + delta)
        .clamp(0, 1 << 30);
    countManager.getRetryCount(targetPostId).value = next;
    countManager.getRetryCount(model.docID).value = next;
    model.stats.retryCount = next;
    currentModel.value = model;
  }

  Future<void> goToPreview() async {
    //flood listing
  }

  Future<void> saveSeeing() async {
    try {
      await _interactionService.recordView(model.docID);
    } catch (_) {}
  }

  Future<void> like() async {
    final uid = _currentUid;
    final bool wasLiked = uid.isNotEmpty && likes.contains(uid);

    try {
      await _postRepository.toggleLike(model);
    } catch (e) {
      if (uid.isNotEmpty) {
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
      Builder(
        builder: (context) => buildPostCommentsSheet(
          context: context,
          postID: model.docID,
          userID: model.userID,
          collection: 'Posts',
          onCommentCountChange: (increment) async {
            await updateCommentCount(increment: increment);
          },
          preferredHeightFactor: 0.55,
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
    if (model.userID == _currentUid) return;
    await onlyFollowUserOneTime();
  }

  Future<void> onlyFollowUserOneTime() async {
    try {
      if (followLoading.value) return;
      followLoading.value = true;
      final outcome = await FollowService.toggleFollowFromLocalState(
        model.userID,
        assumedFollowing: false,
      );
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

    final currentUid = _currentUid;
    if (currentUid.isEmpty) return;

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
    final uid = _currentUid;

    if (increment) {
      commentCount.value++;
      // Yorum yapıldığında kullanıcıyı comments listesine ekle
      if (uid.isNotEmpty && !comments.contains(uid)) {
        comments.add(uid);
      }
    } else if (commentCount.value > 0) {
      commentCount.value--;
      // Yorum silindiğinde kullanıcıyı listeden çıkar (eğer başka yorumu yoksa)
      if (uid.isNotEmpty) {
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
