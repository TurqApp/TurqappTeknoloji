part of 'post_sharers_controller.dart';

extension PostSharersControllerRuntimePart on PostSharersController {
  void _handlePostSharersOnInit() {
    scrollController.addListener(_onScroll);
    loadPostSharers();
  }

  void _handlePostSharersOnClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
  }

  Future<void> loadPostSharers() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      isLoading.value = true;
      isLoadingMore.value = false;
      _lastSharerDoc = null;
      hasMore.value = true;
      postSharers.clear();
      usersData.clear();
      _usingFallbackSharers = false;
      _fallbackSharers = const <PostSharersModel>[];
      _fallbackOffset = 0;

      _resolvedPostId = postID.trim();
      var targetPostId = _resolvedPostId;
      var page = await _postRepository.fetchPostSharersPage(
        targetPostId,
        limit: PostSharersController._pageSize,
      );
      if (page.items.isEmpty && targetPostId.isNotEmpty) {
        final model = await _postRepository.fetchPostById(
          targetPostId,
          preferCache: true,
        );
        final originalPostId = model?.originalPostID.trim() ?? '';
        if (originalPostId.isNotEmpty && originalPostId != targetPostId) {
          targetPostId = originalPostId;
          page = await _postRepository.fetchPostSharersPage(
            targetPostId,
            limit: PostSharersController._pageSize,
          );
        }
      }
      _resolvedPostId = targetPostId;
      if (page.items.isEmpty && targetPostId.isNotEmpty) {
        final fallbackSharers =
            await _postRepository.fetchSharedAsPostSharersFallback(
          targetPostId,
        );
        if (fallbackSharers.isNotEmpty) {
          _usingFallbackSharers = true;
          _fallbackSharers = fallbackSharers;
          _appendFallbackPage(reset: true);
          return;
        }
      }
      _lastSharerDoc = page.lastDoc;
      hasMore.value = page.hasMore;
      postSharers.assignAll(page.items);

      final userIds = page.items
          .map((sharer) => sharer.userID.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false);
      await loadUsersData(userIds);
    } catch (_) {
    } finally {
      _isFetching = false;
      isLoading.value = false;
    }
  }
}
