part of 'post_like_listing_controller.dart';

class _PostLikeListingControllerRuntimePart {
  final PostLikeListingController controller;

  const _PostLikeListingControllerRuntimePart(this.controller);

  void handleOnInit() {
    controller.searchController.addListener(_syncQueryFromInput);
    controller.scrollController.addListener(_onScroll);
    ever<List<LikeUserItem>>(controller.users, (_) => _applyFilter());
    ever<String>(controller.query, (_) => _applyFilter());
    controller.getLikes();
  }

  void handleOnClose() {
    controller.searchController.removeListener(_syncQueryFromInput);
    controller.searchController.dispose();
    controller.scrollController.removeListener(_onScroll);
    controller.scrollController.dispose();
  }

  void onSearchChanged(String value) {
    final normalized = normalizeSearchText(value);
    if (controller.query.value == normalized) return;
    controller.query.value = normalized;
  }

  void _syncQueryFromInput() {
    onSearchChanged(controller.searchController.text);
  }

  Future<void> getLikes() async {
    if (controller._isFetching || !controller.hasMore.value) return;
    controller._isFetching = true;
    controller.isLoadingMore.value = controller.users.isNotEmpty;

    try {
      final page = await controller._postRepository.fetchLikeUserIdsPage(
        controller.postID,
        lastDoc: controller._lastLikeDoc,
        limit: PostLikeListingController._pageSize,
      );
      if (page.userIds.isEmpty) {
        controller.hasMore.value = false;
        return;
      }

      controller._lastLikeDoc = page.lastDoc;
      controller.hasMore.value = page.hasMore;
      final fetched = await Future.wait(page.userIds.map(_fetchUserItem));
      controller.users.addAll(fetched.whereType<LikeUserItem>());
      _applyFilter();
    } finally {
      controller._isFetching = false;
      controller.isLoadingMore.value = false;
    }
  }

  Future<LikeUserItem?> _fetchUserItem(String userID) async {
    try {
      final summary = await controller._userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (summary == null) return null;
      final nickname = summary.nickname.trim();
      final username = summary.preferredName.trim();
      final fullName = summary.displayName.trim();
      final avatarUrl = summary.avatarUrl.trim();
      final searchText = normalizeSearchText([
        nickname,
        username,
        fullName,
        userID,
      ].join(' '));

      return LikeUserItem(
        userID: userID,
        nickname: nickname,
        fullName: fullName,
        avatarUrl: avatarUrl,
        searchText: searchText,
      );
    } catch (_) {
      return null;
    }
  }

  void _applyFilter() {
    final term = normalizeSearchText(controller.query.value);
    if (term.isEmpty) {
      controller.filteredUsers.assignAll(controller.users);
    } else {
      controller.filteredUsers.assignAll(
        controller.users.where((user) => user.searchText.contains(term)),
      );
    }
  }

  void _onScroll() {
    if (!controller.scrollController.hasClients ||
        controller._isFetching ||
        !controller.hasMore.value) {
      return;
    }
    final position = controller.scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 180) {
      controller.getLikes();
    }
  }
}
