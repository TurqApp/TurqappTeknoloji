part of 'story_viewer.dart';

extension StoryViewerStoryPart on _StoryViewerState {
  void _onUserStoryFinished(int currentIndex) {
    _markUserAsFullyViewed(currentIndex);
    final isLastUser = currentIndex == widget.storyOwnerUsers.length - 1;
    if (!isLastUser) {
      _goToAdjacentUser(currentIndex + 1);
    } else {
      _refreshStoryRowAndExit();
    }
  }

  Future<void> _refreshStoryRowAndExit() async {
    try {
      await refreshStoryRowGlobally();
      print('🔄 Story row refreshed after viewing stories');
    } catch (_) {
    } finally {
      Get.back();
    }
  }

  void _onPrevUserRequested(int currentIndex) {
    final isFirstUser = currentIndex == 0;
    if (isFirstUser) {
      Get.back();
      return;
    }
    _goToAdjacentUser(currentIndex - 1);
  }

  void _onScreenshotDetected() {
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) return;
      if (currentPageIndex >= widget.storyOwnerUsers.length) return;
      final storyOwner = widget.storyOwnerUsers[currentPageIndex];
      if (storyOwner.userID == uid) return;
      if (storyOwner.stories.isNotEmpty) {
        final currentStoryId = storyOwner.stories.first.id;
        StoryRepository.ensure().addScreenshotEvent(
          currentStoryId,
          userId: uid,
        );
      }
    } catch (_) {}
  }

  Future<void> _prefetchNext(int index) async {
    try {
      final cacheManager = maybeFindSegmentCacheManager();
      final prefetch = maybeFindPrefetchScheduler();
      final queuedVideoStoryDocIds = <String>[];
      final isWifi = await ConnectivityHelper.isWifi();
      final count = isWifi ? 3 : 1;
      for (int i = 1; i <= count; i++) {
        final next = index + i;
        if (next >= widget.storyOwnerUsers.length) break;
        final nextUser = widget.storyOwnerUsers[next];
        if (nextUser.stories.isEmpty) continue;
        final firstStory = nextUser.stories.first;
        StoryElement? firstVideo;
        for (final element in firstStory.elements) {
          if (element.type == StoryElementType.video &&
              element.content.trim().isNotEmpty) {
            firstVideo = element;
            break;
          }
        }
        if (firstVideo != null &&
            cacheManager != null &&
            cacheManager.isReady) {
          final storyId = firstStory.id.trim();
          final playbackUrl = canonicalizeHlsCdnUrl(firstVideo.content);
          if (storyId.isNotEmpty &&
              hlsRelativePathFromUrlOrPath(playbackUrl) != null) {
            cacheManager.cacheHlsEntry(storyId, playbackUrl);
            queuedVideoStoryDocIds.add(storyId);
          }
        }
        final firstImage = firstStory.elements.firstWhere(
          (e) =>
              e.type == StoryElementType.image ||
              e.type == StoryElementType.gif,
          orElse: () => firstStory.elements.isNotEmpty
              ? firstStory.elements.first
              : StoryElement(
                  type: StoryElementType.text,
                  content: '',
                  width: 0,
                  height: 0,
                  position: const Offset(0, 0),
                ),
        );
        if (firstImage.type == StoryElementType.image ||
            firstImage.type == StoryElementType.gif) {
          final file = await TurqImageCacheManager.instance
              .getSingleFile(firstImage.content);
          final provider = FileImage(File(file.path));
          precacheImage(provider, context).catchError((_) {});
        }
      }
      if (prefetch != null && queuedVideoStoryDocIds.isNotEmpty) {
        for (final docId in queuedVideoStoryDocIds) {
          prefetch.boostDoc(
            docId,
            readySegments: SegmentCacheRuntimeService.globalReadySegmentCount,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _markUserAsFullyViewed(int index) async {
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty || index >= widget.storyOwnerUsers.length) return;
      final user = widget.storyOwnerUsers[index];
      final targetUserId = user.userID;

      if (user.stories.isNotEmpty) {
        final latestStoryTime = _latestStoryMillis(user);
        final latestStoryId = user.stories.first.id;

        await ensureStoryInteractionOptimizer().markStoryViewed(
          targetUserId,
          latestStoryId,
          latestStoryTime,
        );

        await StoryRepository.ensure().markUserStoriesFullyViewed(
          currentUid: uid,
          targetUserId: targetUserId,
          latestStoryTime: latestStoryTime,
        );

        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (_) {}
  }

  int _latestStoryMillis(StoryUserModel user) {
    if (user.stories.isEmpty) return 0;
    return user.stories.first.createdAt.millisecondsSinceEpoch;
  }

  int _computeStartIndex(StoryUserModel user) {
    return 0;
  }
}
