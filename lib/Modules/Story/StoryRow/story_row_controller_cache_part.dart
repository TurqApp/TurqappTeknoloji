part of 'story_row_controller.dart';

extension StoryRowControllerCachePart on StoryRowController {
  Future<void> addMyUserImmediately() async {
    try {
      final myUid = _currentUid;
      if (myUid.isNotEmpty) {
        final data = await _userCache.getProfile(
          myUid,
          preferCache: true,
          cacheOnly: !ContentPolicy.isConnected,
        );
        if (data != null) {
          final existingIndex =
              users.indexWhere((item) => item.userID == myUid);
          final List<StoryModel> existingStories = existingIndex == -1
              ? const <StoryModel>[]
              : users[existingIndex].stories;
          final myUser = StoryUserModel(
            nickname: _resolveStoryNickname(data),
            avatarUrl: _resolveAvatar(data),
            fullName: "${data['firstName'] ?? ""} ${data['lastName'] ?? ""}",
            userID: myUid,
            stories: existingStories,
          );
          if (existingIndex == -1) {
            users.insert(0, myUser);
          } else {
            users[existingIndex] = myUser;
            if (existingIndex != 0) {
              users.removeAt(existingIndex);
              users.insert(0, myUser);
            }
          }
          unawaited(_warmVisibleAvatarFiles(users, take: 6));
        }
      }
    } catch (e) {
      debugPrint("AddMyUserImmediately error: $e");
    }
  }

  Future<void> _warmVisibleAvatarFiles(
    Iterable<StoryUserModel> source, {
    int take = 12,
  }) async {
    final urls = source
        .map((e) => e.avatarUrl.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .take(take)
        .toList();
    if (urls.isEmpty) return;

    for (final url in urls) {
      try {
        await TurqImageCacheManager.instance.getSingleFile(url);
      } catch (_) {}
    }
  }

  Future<void> clearSessionCache() async {
    final ownerUid = _currentUid;
    users.clear();
    _currentLimit = initialLimit;
    _isLoadingMore = false;
    if (ownerUid.isEmpty) return;
    try {
      await _storyRepository.invalidateStoryCachesForUser(
        ownerUid,
        clearDeletedStories: false,
      );
    } catch (e) {
      debugPrint('Story mini cache clear error: $e');
    }
  }

  Future<void> _loadStoriesFromMiniCache({bool allowExpired = false}) async {
    try {
      final expectedUid = userService.effectiveUserId;
      final loaded = await _storyRepository.restoreStoryRowCache(
        ownerUid: expectedUid,
        allowExpired: allowExpired,
      );
      if (loaded.isNotEmpty) {
        users.assignAll(loaded);
        unawaited(_warmVisibleAvatarFiles(loaded));
      }
      _ensureMyUserPlaceholder();
    } catch (e) {
      debugPrint('Story mini cache load error: $e');
    }
  }
}
