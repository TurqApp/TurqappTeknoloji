part of 'short_content_controller.dart';

extension ShortContentControllerActionsPart on ShortContentController {
  Future<void> toggleLike() async {
    try {
      await _postRepository.toggleLike(model);
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.like_failed'.tr);
    }
  }

  Future<void> like() => toggleLike();

  Future<void> toggleSave() async {
    try {
      await _postRepository.toggleSave(model);
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.save_failed'.tr);
    }
  }

  Future<void> save() => toggleSave();

  Future<void> toggleReshare() async {
    try {
      final newReshareStatus = await _postRepository.toggleReshare(model);
      if (newReshareStatus) {
        ProfileController.maybeFind()?.getResharesSingle();
      } else {
        ProfileController.maybeFind()?.removeReshare(model.docID);
      }
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.reshare_failed'.tr);
    }
  }

  Future<void> reshare() => toggleReshare();

  Future<void> reportPost() async {
    try {
      final success = await _interactionService.reportPost(model.docID);
      if (success) {
        isReported.value = true;
        reportCount.value++;
        AppSnackbar('common.success'.tr, 'post.report_success'.tr);
      } else {
        AppSnackbar('common.info'.tr, 'post.already_reported'.tr);
      }
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.report_failed'.tr);
    }
  }

  Future<void> gizle() async {
    final shortController = ShortController.maybeFind();
    final index = shortController?.shorts.indexOf(model) ?? -1;
    if (index >= 0) shortController!.shorts[index].gizlendi = true;
    final explore = ExploreController.maybeFind();

    final index3 = explore?.explorePosts.indexOf(model) ?? -1;
    if (index3 >= 0) explore!.explorePosts[index3].gizlendi = true;

    final index4 = explore?.explorePhotos.indexOf(model) ?? -1;
    if (index4 >= 0) explore!.explorePhotos[index4].gizlendi = true;

    final index5 = explore?.exploreVideos.indexOf(model) ?? -1;
    if (index5 >= 0) explore!.exploreVideos[index5].gizlendi = true;

    final store8 = AgendaController.maybeFind();
    final index8 = store8?.agendaList.indexOf(model) ?? -1;
    if (index8 >= 0) store8!.agendaList[index8].gizlendi = true;

    final profile = ProfileController.maybeFind();
    final index9 = profile?.allPosts.indexOf(model) ?? -1;
    if (index9 >= 0) profile!.allPosts[index9].gizlendi = true;

    final index10 = profile?.allPosts.indexOf(model) ?? -1;
    if (index10 >= 0) profile!.allPosts[index10].gizlendi = true;

    gizlendi.value = true;
  }

  Future<void> gizlemeyiGeriAl() async {
    final shortController = ShortController.maybeFind();
    final index = shortController?.shorts.indexOf(model) ?? -1;
    if (index >= 0) shortController!.shorts[index].gizlendi = false;

    final explore = ExploreController.maybeFind();

    final index3 = explore?.explorePosts.indexOf(model) ?? -1;
    if (index3 >= 0) explore!.explorePosts[index3].gizlendi = false;

    final index4 = explore?.explorePhotos.indexOf(model) ?? -1;
    if (index4 >= 0) explore!.explorePhotos[index4].gizlendi = false;

    final index5 = explore?.exploreVideos.indexOf(model) ?? -1;
    if (index5 >= 0) explore!.exploreVideos[index5].gizlendi = false;

    final store8 = AgendaController.maybeFind();
    final index8 = store8?.agendaList.indexOf(model) ?? -1;
    if (index8 >= 0) store8!.agendaList[index8].gizlendi = false;

    final profile = ProfileController.maybeFind();
    final index9 = profile?.allPosts.indexOf(model) ?? -1;
    if (index9 >= 0) profile!.allPosts[index9].gizlendi = false;

    final index10 = profile?.allPosts.indexOf(model) ?? -1;
    if (index10 >= 0) profile!.allPosts[index10].gizlendi = false;

    gizlendi.value = false;
  }

  Future<void> arsivle() async {
    await _postRepository.setArchived(model, true);

    final shortController = ShortController.maybeFind();
    final index = shortController?.shorts.indexOf(model) ?? -1;
    if (index >= 0) shortController!.shorts[index].arsiv = true;

    final explore = ExploreController.maybeFind();

    final index3 = explore?.explorePosts.indexOf(model) ?? -1;
    if (index3 >= 0) explore!.explorePosts[index3].arsiv = true;

    final index4 = explore?.explorePhotos.indexOf(model) ?? -1;
    if (index4 >= 0) explore!.explorePhotos[index4].arsiv = true;

    final index5 = explore?.exploreVideos.indexOf(model) ?? -1;
    if (index5 >= 0) explore!.exploreVideos[index5].arsiv = true;

    final store8 = AgendaController.maybeFind();
    final index8 = store8?.agendaList.indexOf(model) ?? -1;
    if (index8 >= 0) store8!.agendaList[index8].arsiv = true;

    final profile = ProfileController.maybeFind();
    final profileIndex = profile?.allPosts.indexOf(model) ?? -1;
    if (profileIndex >= 0) profile!.allPosts[profileIndex].arsiv = true;

    arsivlendi.value = true;
  }

  Future<void> arsivdenCikart() async {
    await _postRepository.setArchived(model, false);

    final shortController = ShortController.maybeFind();
    final index = shortController?.shorts.indexOf(model) ?? -1;
    if (index >= 0) shortController!.shorts[index].arsiv = false;

    final explore = ExploreController.maybeFind();

    final index3 = explore?.explorePosts.indexOf(model) ?? -1;
    if (index3 >= 0) explore!.explorePosts[index3].arsiv = false;

    final index4 = explore?.explorePhotos.indexOf(model) ?? -1;
    if (index4 >= 0) explore!.explorePhotos[index4].arsiv = false;

    final index5 = explore?.exploreVideos.indexOf(model) ?? -1;
    if (index5 >= 0) explore!.exploreVideos[index5].arsiv = false;

    final store8 = AgendaController.maybeFind();
    final index8 = store8?.agendaList.indexOf(model) ?? -1;
    if (index8 >= 0) store8!.agendaList[index8].arsiv = false;

    final profile = ProfileController.maybeFind();
    final profileIndex = profile?.allPosts.indexOf(model) ?? -1;
    if (profileIndex >= 0) profile!.allPosts[profileIndex].arsiv = false;

    arsivlendi.value = false;
  }

  Future<void> sil() async {
    await PostDeleteService.instance.softDelete(model);
    if (isClosed) return;
    silindi.value = true;

    _deleteFadeTimer?.cancel();
    _deleteFadeTimer = Timer(const Duration(milliseconds: 2600), () {
      if (isClosed) return;
      silindiOpacity.value = 0.0;
    });

    _deleteRemoveTimer?.cancel();
    _deleteRemoveTimer = Timer(const Duration(seconds: 3), () {
      if (isClosed) return;
      final shortController = ShortController.maybeFind();
      if (shortController != null) {
        final idx =
            shortController.shorts.indexWhere((e) => e.docID == model.docID);
        if (idx != -1) {
          shortController.shorts.removeAt(idx);
          shortController.shorts.refresh();
        }
      }
    });
  }

  Future<void> sendPost() async {
    Get.bottomSheet(
      Container(
        height: Get.height / 1.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(12),
            topLeft: Radius.circular(12),
          ),
        ),
        child: ShareGrid(postID: model.docID, postType: "Post"),
      ),
    );
  }

  Future<void> onlyFollowUserOneTime() async {
    if (followLoading.value) return;

    try {
      final currentUid = _currentUserId;
      final alreadyFollowing = await FollowRepository.ensure().isFollowing(
        model.userID,
        currentUid: currentUid,
        preferCache: true,
      );
      if (alreadyFollowing) {
        takipEdiyorum.value = true;
        return;
      }
      followLoading.value = true;
      final outcome = await FollowService.toggleFollow(model.userID);
      if (outcome.nowFollowing) {
        takipEdiyorum.value = true;
      }
      if (outcome.limitReached) {
        AppSnackbar('following.limit_title'.tr, 'following.limit_body'.tr);
      }
    } catch (_) {
    } finally {
      followLoading.value = false;
    }
  }
}
