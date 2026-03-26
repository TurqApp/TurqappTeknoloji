part of 'photo_short_content_controller.dart';

extension PhotoShortContentControllerSocialPart
    on PhotoShortsContentController {
  Future<void> fetchUserData(String userID) async {
    final postLevelAvatar = model.authorAvatarUrl.trim();
    final postLevelNickname = model.authorNickname.trim();
    final postLevelDisplayName = model.authorDisplayName.trim();
    final hasPostLevelIdentity = postLevelAvatar.isNotEmpty &&
        postLevelNickname.isNotEmpty &&
        postLevelDisplayName.isNotEmpty;

    if (hasPostLevelIdentity) {
      avatarUrl.value = postLevelAvatar;
      nickname.value = postLevelNickname;
      token.value = '';
      fullName.value = postLevelDisplayName;
      takipEdiyorum.value = await ensureFollowRepository().isFollowing(
        userID,
        currentUid: _currentUserId,
        preferCache: true,
      );
      return;
    }

    final summary = await _userSummaryResolver.resolve(
      userID,
      preferCache: true,
    );
    if (summary != null) {
      avatarUrl.value = model.authorAvatarUrl.trim().isNotEmpty
          ? model.authorAvatarUrl.trim()
          : summary.avatarUrl;
      nickname.value = model.authorNickname.trim().isNotEmpty
          ? model.authorNickname.trim()
          : (summary.nickname.isNotEmpty
              ? summary.nickname
              : summary.preferredName);
      token.value = summary.token;
      fullName.value = model.authorDisplayName.trim().isNotEmpty
          ? model.authorDisplayName.trim()
          : summary.displayName;
    }

    takipEdiyorum.value = await ensureFollowRepository().isFollowing(
      userID,
      currentUid: _currentUserId,
      preferCache: true,
    );
  }

  Future<void> toggleFollowStatus(String userID) async {
    if (followLoading.value) return;
    final wasFollowing = takipEdiyorum.value;
    takipEdiyorum.value = !wasFollowing;
    followLoading.value = true;
    try {
      final outcome = await FollowService.toggleFollowFromLocalState(
        userID,
        assumedFollowing: wasFollowing,
      );
      takipEdiyorum.value = outcome.nowFollowing;
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

  Future<void> showPostCommentsBottomSheet() async {
    await Get.bottomSheet(
      Builder(
        builder: (context) => buildPostCommentsSheet(
          context: context,
          postID: model.docID,
          userID: model.userID,
          collection: 'Posts',
          onCommentCountChange: (bool increment) async {
            await countManager.updateCommentCount(
              model.docID,
              model.originalPostID,
              increment: increment,
            );
          },
          preferredHeightFactor: 0.5,
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
  }

  Future<void> getComments() async {
    comments.clear();
    userComments.clear();
  }

  Future<void> getReSharedUsers(String docID) async {
    final uid = _currentUserId;
    if (uid.isEmpty) {
      reSharedUsers.clear();
      return;
    }
    _postState ??= _postRepository.attachPost(model);
    reSharedUsers.value =
        (_postState?.reshared.value ?? false) ? <String>[uid] : <String>[];
  }

  Future<void> getSaved() async {
    final uid = _currentUserId;
    if (uid.isEmpty) {
      saved.clear();
      return;
    }
    _postState ??= _postRepository.attachPost(model);
    saved.value =
        (_postState?.saved.value ?? false) ? <String>[uid] : <String>[];
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

  Future<void> sendAdminPushForPost() async {
    if (!canSendAdminPush) return;

    final currentUid = _currentUserId;
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
      AppSnackbar('common.error'.tr, 'admin_push.failed_body'.tr);
    } catch (e) {
      AppSnackbar('common.error'.tr, 'admin_push.failed_body'.tr);
    }
  }
}
