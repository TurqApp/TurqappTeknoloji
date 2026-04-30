part of 'share_grid_controller_library.dart';

extension ShareGridControllerRuntimePart on ShareGridController {
  void _handleShareGridInit() {
    searchFocus.value.addListener(() => searchFocus.refresh());
    getFolowers();
  }

  void _handleShareGridClose() {
    _searchDebounce?.cancel();
    search.dispose();
    searchFocus.value.dispose();
  }

  Future<void> getFolowers() async {
    final currentUid = ((await CurrentUserService.instance.ensureAuthReady(
              waitForAuthState: true,
              forceTokenRefresh: true,
              timeout: const Duration(seconds: 8),
            )) ??
            CurrentUserService.instance.authUserId)
        .trim();
    if (currentUid.isEmpty) {
      followings.clear();
      return;
    }
    final ids = await _visibilityPolicy.loadViewerFollowingIds(
      viewerUserId: currentUid,
    );
    final limitedIds = ids.take(20).toList();
    final profiles = await _userSummaryResolver.resolveMany(limitedIds);
    final items = <OgrenciModel>[];
    for (final userId in limitedIds) {
      final data = profiles[userId];
      if (data == null) continue;
      items.add(OgrenciModel(
        userID: userId,
        firstName: data.displayName,
        avatarUrl: data.avatarUrl,
        lastName: '',
        nickname: data.nickname,
      ));
    }
    followings.assignAll(items);
  }

  Future<void> sendIt() async {
    final selected = selectedUser.value;
    if (selected == null) {
      AppSnackbar('common.warning'.tr, 'share_grid.select_user_first'.tr);
      return;
    }
    final userID = selected.userID;
    final sohbet = chatListingController.list.firstWhereOrNull(
      (val) => val.userID == userID,
    );
    final currentUID = ((await CurrentUserService.instance.ensureAuthReady(
              waitForAuthState: true,
              forceTokenRefresh: true,
              timeout: const Duration(seconds: 8),
            )) ??
            CurrentUserService.instance.authUserId)
        .trim();
    if (currentUID.isEmpty) {
      AppSnackbar('common.error'.tr, 'chat.message_send_failed'.tr);
      return;
    }
    final chatId = sohbet?.chatID ?? buildConversationId(currentUID, userID);

    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await _conversationRepository.ensureConversationForPostShare(
        chatId: chatId,
        currentUid: currentUID,
        otherUid: userID,
        nowMs: nowMs,
      );

      await _conversationRepository.addPostShareMessage(
        chatId: chatId,
        currentUid: currentUID,
        postId: postID,
        postType: postType,
      );

      search.text = "";
      searchFocus.value.unfocus();
      selectedUser.value = null;
      Get.back();
      AppSnackbar('common.success'.tr, 'share_grid.post_forwarded'.tr);
      chatListingController.getList();
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        'share_grid.forward_failed'.trParams({'error': '$e'}),
      );
    }
  }

  void searchUser(String keyword) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final normalizedKeyword = keyword.trim();
      if (normalizedKeyword.isEmpty) {
        followings.clear();
        await getFolowers();
        return;
      }

      final results = await _userRepository.searchUsersByNicknamePrefix(
        normalizedKeyword,
        limit: 20,
      );

      followings.assignAll(
        results
            .map((raw) => OgrenciModel.fromMap(
                  (raw['id'] ?? '').toString(),
                  raw,
                ))
            .where((user) => user.userID.isNotEmpty)
            .toList(growable: false),
      );
    });
  }
}
