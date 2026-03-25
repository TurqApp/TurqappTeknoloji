part of 'notification_content_controller.dart';

class _NotificationContentControllerRuntimePart {
  final NotificationContentController _controller;

  const _NotificationContentControllerRuntimePart(this._controller);

  void handleOnInit() {
    _loadUser();
    _loadFollowingState();
    _loadTargetHint();
  }

  Future<void> getPostData(String docID) async {
    final lookup = await _controller._notifyLookupRepository.getPostLookup(
      docID,
    );
    final model = lookup.model;
    if (model == null) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final isVisibleNow = model.timeStamp <= nowMs;
    if (isVisibleNow && model.deletedPost != true) {
      _controller.model.value = model;
      _controller.targetHint.value = _buildPostHint(model);
    } else {
      _controller.model.value = PostsModel.empty();
    }
  }

  Future<void> _loadTargetHint() async {
    final normalizedType = normalizeNotificationType(
      _controller.notification.type,
      _controller.notification.postType,
    );
    final postId = _controller.notification.postID.trim();

    if (normalizedType == 'follow' || normalizedType == 'user') {
      _controller.targetHint.value = 'notification.hint.profile'.tr;
      return;
    }

    if (normalizedType == 'message' || normalizedType == 'chat') {
      _controller.targetHint.value = 'notification.hint.chat'.tr;
      return;
    }

    if (postId.isEmpty) {
      _controller.targetHint.value = _fallbackHint(normalizedType);
      return;
    }

    if (isNotificationPostType(normalizedType)) {
      await getPostData(postId);
      if (_controller.targetHint.value.isEmpty) {
        _controller.targetHint.value = _fallbackHint(normalizedType);
      }
      return;
    }

    if (isJobNotificationType(normalizedType)) {
      final lookup = await _controller._notifyLookupRepository.getJobLookup(
        postId,
      );
      final label = lookup.model?.ilanBasligi.trim().isNotEmpty == true
          ? lookup.model!.ilanBasligi.trim()
          : lookup.model?.brand.trim() ?? '';
      _controller.targetHint.value = label.isNotEmpty
          ? 'notification.hint.listing_named'.trParams({'label': label})
          : 'notification.hint.listing'.tr;
      return;
    }

    if (isTutoringNotificationType(normalizedType)) {
      final lookup =
          await _controller._notifyLookupRepository.getTutoringLookup(postId);
      final label = lookup.model?.baslik.trim() ?? '';
      _controller.targetHint.value = label.isNotEmpty
          ? 'notification.hint.listing_named'.trParams({'label': label})
          : 'notification.hint.tutoring'.tr;
      return;
    }

    _controller.targetHint.value = _fallbackHint(normalizedType);
  }

  String _buildPostHint(PostsModel post) {
    final normalizedType = normalizeNotificationType(
      _controller.notification.type,
      _controller.notification.postType,
    );
    final rawTitle = _controller.notification.title.trim();
    final preview = rawTitle.isNotEmpty
        ? rawTitle
        : post.metin.trim().isNotEmpty
            ? post.metin.trim()
            : post.konum.trim();
    final normalizedPreview = preview.replaceAll(RegExp(r'\s+'), ' ').trim();
    final prefix = normalizedType == NotificationContentController._commentType
        ? 'notification.hint.comments'.tr
        : 'notification.hint.post'.tr;
    if (normalizedPreview.isEmpty) return prefix;
    return '$prefix: $normalizedPreview';
  }

  String _fallbackHint(String normalizedType) {
    if (normalizedType == NotificationContentController._commentType) {
      return 'notification.hint.comments'.tr;
    }
    if (isJobNotificationType(normalizedType) ||
        normalizedType == NotificationContentController._jobApplicationType) {
      return 'notification.hint.listing'.tr;
    }
    if (isTutoringNotificationType(normalizedType) ||
        normalizedType ==
            NotificationContentController._tutoringApplicationType) {
      return 'notification.hint.tutoring'.tr;
    }
    if (normalizedType == 'message' ||
        normalizedType == NotificationContentController._chatType) {
      return 'notification.hint.chat'.tr;
    }
    if (normalizedType == 'follow' ||
        normalizedType == NotificationContentController._userType) {
      return 'notification.hint.profile'.tr;
    }
    return 'notification.hint.post'.tr;
  }

  Future<void> _loadUser() async {
    final user = await _controller._userSummaryResolver.resolve(
      _controller.userID,
      preferCache: true,
    );
    if (user == null) {
      _controller.avatarUrl.value = '';
      _controller.nickname.value = 'app.name'.tr;
      return;
    }
    _controller.avatarUrl.value = user.avatarUrl;
    _controller.nickname.value =
        user.nickname.isNotEmpty ? user.nickname : user.preferredName;
  }

  Future<void> _loadFollowingState() async {
    final currentUid = CurrentUserService.instance.effectiveUserId;
    if (currentUid.isEmpty) return;
    _controller.following.value =
        await _controller._followRepository.isFollowing(
      _controller.userID,
      currentUid: currentUid,
      preferCache: true,
    );
  }
}
