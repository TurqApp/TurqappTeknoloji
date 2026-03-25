part of 'short_content_controller.dart';

extension ShortContentControllerDataPart on ShortContentController {
  void _initializeStats() {
    likeCount.value = model.stats.likeCount.toInt();
    commentCount.value = model.stats.commentCount.toInt();
    savedCount.value = model.stats.savedCount.toInt();
    retryCount.value = model.stats.retryCount.toInt();
    viewCount.value = model.stats.statsCount.toInt();
    reportCount.value = model.stats.reportedCount.toInt();
  }

  Future<void> _loadUserInteractionStatus() async {
    try {
      _postState ??= _shortPostRepository.attachPost(model);
      _syncSharedInteractionState();
    } catch (_) {}
  }

  void _bindPostStatsListener() {
    _postState ??= _shortPostRepository.attachPost(model);
    _postDataWorker?.dispose();
    _postDataWorker =
        ever<Map<String, dynamic>?>(_postState!.latestPostData, (data) {
      if (isClosed || data == null) return;
      final stats = data['stats'] as Map<String, dynamic>? ?? const {};
      likeCount.value = ((stats['likeCount'] ?? 0) as num)
          .toInt()
          .clamp(0, double.infinity)
          .toInt();
      commentCount.value = ((stats['commentCount'] ?? 0) as num)
          .toInt()
          .clamp(0, double.infinity)
          .toInt();
      savedCount.value = ((stats['savedCount'] ?? 0) as num)
          .toInt()
          .clamp(0, double.infinity)
          .toInt();
      retryCount.value = ((stats['retryCount'] ?? 0) as num)
          .toInt()
          .clamp(0, double.infinity)
          .toInt();
      viewCount.value = ((stats['statsCount'] ?? 0) as num)
          .toInt()
          .clamp(0, double.infinity)
          .toInt();
      reportCount.value = ((stats['reportedCount'] ?? 0) as num)
          .toInt()
          .clamp(0, double.infinity)
          .toInt();
    });
    _interactionWorker?.dispose();
    _interactionWorker = everAll([
      _postState!.liked,
      _postState!.saved,
      _postState!.reshared,
      _postState!.reported,
    ], (_) {
      _syncSharedInteractionState();
    });
  }

  void _syncSharedInteractionState() {
    if (isClosed || _postState == null) return;
    isLiked.value = _postState!.liked.value;
    isSaved.value = _postState!.saved.value;
    isReshared.value = _postState!.reshared.value;
    isReported.value = _postState!.reported.value;
  }

  Future<void> getGizleArsivSikayetEdildi() async {
    gizlendi.value = model.gizlendi;
    arsivlendi.value = model.arsiv;
    silindi.value = model.deletedPost;
  }

  Future<void> getYenidenPaylasBilgisi() async {
    retryCount.value = _postState?.latestPostData.value == null
        ? model.stats.retryCount.toInt()
        : (((_postState!.latestPostData.value!['stats']
                    as Map<String, dynamic>?)?['retryCount'] ??
                model.stats.retryCount) as num)
            .toInt();
  }

  Future<void> getSeens() async {}

  Future<void> saveSeeing() async {
    try {
      await _shortInteractionService.recordView(model.docID);
    } catch (_) {}
  }

  Future<void> fetchUserData(String userID) async {
    final postLevelAvatar = model.authorAvatarUrl.trim();
    final postLevelNickname = model.authorNickname.trim();
    final postLevelDisplayName = model.authorDisplayName.trim();
    final hasPostLevelIdentity = postLevelAvatar.isNotEmpty &&
        postLevelNickname.isNotEmpty &&
        postLevelDisplayName.isNotEmpty;

    if (hasPostLevelIdentity) {
      if (isClosed) return;
      avatarUrl.value = postLevelAvatar;
      nickname.value = postLevelNickname;
      fullName.value = postLevelDisplayName;
      token.value = '';
      takipEdiyorum.value = await FollowRepository.ensure().isFollowing(
        userID,
        currentUid: _shortCurrentUserId,
        preferCache: true,
      );
      return;
    }

    final summary = await _shortUserSummaryResolver.resolve(
      userID,
      preferCache: true,
      cacheOnly: false,
    );
    if (isClosed) return;
    final resolvedAvatar = summary?.avatarUrl.trim().isNotEmpty == true
        ? summary!.avatarUrl.trim()
        : '';
    avatarUrl.value =
        postLevelAvatar.isNotEmpty ? postLevelAvatar : resolvedAvatar;
    nickname.value = postLevelNickname.isNotEmpty
        ? postLevelNickname
        : (summary?.nickname.trim().isNotEmpty == true
            ? summary!.nickname.trim()
            : '');
    token.value = summary?.token ?? '';
    fullName.value = postLevelDisplayName.isNotEmpty
        ? postLevelDisplayName
        : (summary?.displayName.trim().isNotEmpty == true
            ? summary!.displayName.trim()
            : nickname.value);

    takipEdiyorum.value = await FollowRepository.ensure().isFollowing(
      userID,
      currentUid: _shortCurrentUserId,
      preferCache: true,
    );
  }
}
