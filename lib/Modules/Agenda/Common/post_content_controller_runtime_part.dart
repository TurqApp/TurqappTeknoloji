part of 'post_content_controller.dart';

extension PostContentControllerRuntimePart on PostContentController {
  AgendaController _performResolveAgendaController() {
    return AgendaController.ensure();
  }

  Future<void> _performOnReshareAdded(
    String? uid, {
    String? targetPostId,
  }) async {
    if (!scrollFeedToTopOnReshare) return;
    try {
      final controller = agendaController.scrollController;
      if (controller.hasClients) {
        await controller.animateTo(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    } catch (_) {}
  }

  void _handlePostContentInit() {
    unawaited(_hydrateAdminPushPermission());
    _bindMembershipListeners();
    _bindPostDocCounts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      countManager.initializeCounts(
        model.docID,
        likeCount: model.stats.likeCount.toInt(),
        commentCount: model.stats.commentCount.toInt(),
        savedCount: model.stats.savedCount.toInt(),
        retryCount: model.stats.retryCount.toInt(),
        statsCount: model.stats.statsCount.toInt(),
      );
      _initializeStats();
    });

    getGizleArsivSikayetEdildi();
    getUserData(model.userID);
    getReSharedUsers(model.docID);
    saveSeeing();
    followCheck();
    _bindFollowingState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      onPostFrameBound();
    });

    onPostInitialized();
  }

  Future<void> _hydrateAdminPushPermission() async {
    final allowed = await AdminAccessService.canAccessTask('admin_push');
    if (_canSendAdminPush == allowed) return;
    _canSendAdminPush = allowed;
    update();
  }

  void _handlePostContentClose() {
    _interactionWorker?.dispose();
    _postDataWorker?.dispose();
    _postRepository.releasePost(model.docID);
    _userSub?.cancel();
    _likeDocSub?.cancel();
    _savedDocSub?.cancel();
    _reshareDocSub?.cancel();
    _postDocSub?.cancel();
    _currentUserStreamSub?.cancel();
    _followingWorker?.dispose();
    _myResharesWorker?.dispose();
  }
}
