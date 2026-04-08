part of 'agenda_controller.dart';

extension AgendaControllerLifecyclePart on AgendaController {
  void _disposeFeedScrollControllerSafely() {
    final controller = scrollController;
    try {
      controller.removeListener(_onScroll);
    } catch (_) {}

    void disposeWhenDetached([int remainingFrames = 8]) {
      bool attached = false;
      try {
        attached = controller.positions.isNotEmpty;
      } catch (_) {}

      if (!attached) {
        try {
          controller.dispose();
        } catch (_) {}
        return;
      }

      if (remainingFrames <= 0) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        disposeWhenDetached(remainingFrames - 1);
      });
    }

    disposeWhenDetached();
  }

  void _handleLifecycleInit() {
    scrollController.addListener(_onScroll);
    navBarController = ensureNavBarController();
    unawaited(DeviceSessionService.instance.warmDeviceKey());
    unawaited(FeedDiversityMemoryService.ensure().ensureReady());
    _bindFollowingListener();
    _bindCenteredIndexListener();
    _bindMergedFeedEntries();
    _bindFilteredFeedEntries();
    _bindRenderFeedEntries();
  }

  void _handleLifecycleReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (playbackSuspended.value) return;
      _scheduleFeedPrefetch();
    });
  }

  void _handleLifecycleClose() {
    _mergedFeedWorker?.dispose();
    _filteredFeedWorker?.dispose();
    _renderFeedWorker?.dispose();
    _visibilityDebounce?.cancel();
    _feedPrefetchDebounce?.cancel();
    _scrollIdleDebounce?.cancel();
    _playbackReassertTimer?.cancel();
    _reshareWarmupTimer?.cancel();
    _resharePostsFetchTimer?.cancel();
    _agendaRetryTimer?.cancel();
    _deferredInitialNetworkBootstrapTimer?.cancel();
    _startupPromoRevealTimer?.cancel();
    _startupRenderStageTimer?.cancel();
    unawaited(persistWarmLaunchCache());
    _disposeFeedScrollControllerSafely();
  }

  // ignore: unused_element
  Future<void> _performAddNewReshareEntryWithoutScroll(
    String postId,
    String reshareUserID,
  ) async {
    try {
      final currentOffset =
          scrollController.hasClients ? scrollController.offset : 0.0;
      final post = agendaList.firstWhereOrNull((p) => p.docID == postId);
      if (post == null) {
        final fetchedPost = await _postRepository.fetchPostById(
          postId,
          preferCache: true,
        );
        if (fetchedPost == null) return;
        if (!await _canViewerSeePost(fetchedPost)) return;

        final reshareEntry = {
          'type': 'reshare',
          'post': fetchedPost,
          'reshareTimestamp': DateTime.now().millisecondsSinceEpoch,
          'reshareUserID': reshareUserID,
          'originalUserID': fetchedPost.originalUserID.isNotEmpty
              ? fetchedPost.originalUserID
              : fetchedPost.userID,
          'originalPostID': fetchedPost.originalPostID.isNotEmpty
              ? fetchedPost.originalPostID
              : fetchedPost.docID,
        };

        feedReshareEntries.insert(0, reshareEntry);
      } else {
        if (!await _canViewerSeePost(post)) return;
        final reshareEntry = {
          'type': 'reshare',
          'post': post,
          'reshareTimestamp': DateTime.now().millisecondsSinceEpoch,
          'reshareUserID': reshareUserID,
          'originalUserID': post.originalUserID.isNotEmpty
              ? post.originalUserID
              : post.userID,
          'originalPostID':
              post.originalPostID.isNotEmpty ? post.originalPostID : post.docID,
        };

        feedReshareEntries.insert(0, reshareEntry);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (scrollController.hasClients) {
          await scrollController.animateTo(
            currentOffset,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('addNewReshareEntryWithoutScroll error: $e');
    }
  }

  // ignore: unused_element
  void _performRemoveReshareEntry(String postId, String reshareUserID) {
    try {
      feedReshareEntries.removeWhere((entry) {
        final entryPost = entry['post'] as PostsModel;
        final entryUserID = (entry['reshareUserID'] ?? '').toString();
        final entryOriginalPostID =
            (entry['originalPostID'] ?? '').toString().trim();
        final entryPostID = entryPost.docID.trim();
        final normalizedTarget = postId.trim();
        final matchesPost = entryPostID == normalizedTarget ||
            entryOriginalPostID == normalizedTarget ||
            entryPost.originalPostID.trim() == normalizedTarget;
        final matchesUser = entryUserID == reshareUserID;
        return matchesPost && matchesUser;
      });
      feedReshareEntries.refresh();
    } catch (e) {
      print('removeReshareEntry error: $e');
    }
  }

  void _performSuspendPlaybackForOverlay() {
    playbackSuspended.value = true;
    _cancelPendingPlaybackReassert();
    _visibleFractions.clear();
    _visibleUpdatedAt.clear();
    _lastPlaybackWindowSignature = null;
    _lastPlaybackRowUpdateDocId = null;
    centeredIndex.value = -1;
    try {
      VideoStateManager.instance.pauseAllVideos(force: true);
    } catch (_) {}
    try {
      AudioFocusCoordinator.instance.pauseAllAudioPlayers();
    } catch (_) {}
  }

  void _performResumePlaybackAfterOverlay() {
    playbackSuspended.value = false;
    resumeFeedPlayback();
  }

  void _performBindFollowingListener() {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    _fetchFollowingAndReshares(uid);
  }
}
