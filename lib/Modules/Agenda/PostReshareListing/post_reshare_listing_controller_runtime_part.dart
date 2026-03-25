part of 'post_reshare_listing_controller.dart';

class _PostReshareListingControllerRuntimePart {
  static void onInit(PostReshareListingController controller) {
    controller.reshareScrollController.addListener(
      () => _onReshareScroll(controller),
    );
    controller.quoteScrollController.addListener(
      () => _onQuoteScroll(controller),
    );
    controller.loadMoreReshares(initial: true);
  }

  static void onClose(PostReshareListingController controller) {
    controller.reshareScrollController.dispose();
    controller.quoteScrollController.dispose();
  }

  static void ensureQuotesLoaded(PostReshareListingController controller) {
    if (controller._quotesInitialized) return;
    controller._quotesInitialized = true;
    controller.loadMoreQuotes(initial: true);
  }

  static Future<void> loadMoreReshares(
    PostReshareListingController controller, {
    bool initial = false,
  }) async {
    if (controller._fetchingReshares || !controller.hasMoreReshares.value) {
      return;
    }
    controller._fetchingReshares = true;
    if (initial) {
      controller.isLoadingReshares.value = true;
    } else {
      controller.isLoadingMoreReshares.value = true;
    }

    try {
      final page = await controller._postRepository.fetchReshareUserIdsPage(
        controller.postID,
        lastDoc: controller._lastReshareDoc,
        limit: PostReshareListingController._pageSize,
      );
      if (page.userIds.isEmpty) {
        controller.hasMoreReshares.value = false;
        return;
      }

      controller._lastReshareDoc = page.lastDoc;
      controller.hasMoreReshares.value = page.hasMore;

      final fetched = await Future.wait(page.userIds.map(
        (userId) => _fetchUserItem(controller, userId),
      ));
      final existingIds = controller.reshareUsers.map((e) => e.userID).toSet();
      controller.reshareUsers.addAll(
        fetched.whereType<ReshareUserItem>().where(
              (item) => existingIds.add(item.userID),
            ),
      );
    } finally {
      controller._fetchingReshares = false;
      controller.isLoadingReshares.value = false;
      controller.isLoadingMoreReshares.value = false;
    }
  }

  static Future<void> loadMoreQuotes(
    PostReshareListingController controller, {
    bool initial = false,
  }) async {
    if (controller._fetchingQuotes || !controller.hasMoreQuotes.value) {
      return;
    }
    controller._fetchingQuotes = true;
    if (initial) {
      controller.isLoadingQuotes.value = true;
    } else {
      controller.isLoadingMoreQuotes.value = true;
    }

    final newItems = <ReshareUserItem>[];
    final existingIds = controller.quoteUsers.map((e) => e.userID).toSet();

    try {
      final page = await controller._postRepository.fetchQuoteUserIdsPage(
        controller.postID,
        lastDoc: controller._lastQuoteSharerDoc,
        limit: PostReshareListingController._pageSize,
      );
      controller._lastQuoteSharerDoc = page.lastDoc;
      controller.hasMoreQuotes.value = page.hasMore;

      final fetched = await Future.wait(page.userIds.map(
        (userId) => _fetchUserItem(controller, userId),
      ));
      for (final item in fetched.whereType<ReshareUserItem>()) {
        if (existingIds.add(item.userID)) {
          newItems.add(item);
        }
      }

      controller.quoteUsers.addAll(newItems);
    } finally {
      controller._fetchingQuotes = false;
      controller.isLoadingQuotes.value = false;
      controller.isLoadingMoreQuotes.value = false;
    }
  }

  static Future<ReshareUserItem?> _fetchUserItem(
    PostReshareListingController controller,
    String userID,
  ) async {
    try {
      final summary = await controller._userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (summary == null) return null;
      return ReshareUserItem(
        userID: userID,
        nickname: summary.nickname.trim(),
        fullName: summary.displayName.trim(),
        avatarUrl: summary.avatarUrl.trim(),
      );
    } catch (_) {
      return null;
    }
  }

  static void _onReshareScroll(PostReshareListingController controller) {
    if (!controller.reshareScrollController.hasClients ||
        controller._fetchingReshares ||
        !controller.hasMoreReshares.value) {
      return;
    }
    final position = controller.reshareScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 180) {
      controller.loadMoreReshares();
    }
  }

  static void _onQuoteScroll(PostReshareListingController controller) {
    if (!controller.quoteScrollController.hasClients ||
        controller._fetchingQuotes ||
        !controller.hasMoreQuotes.value) {
      return;
    }
    final position = controller.quoteScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 180) {
      controller.loadMoreQuotes();
    }
  }
}
