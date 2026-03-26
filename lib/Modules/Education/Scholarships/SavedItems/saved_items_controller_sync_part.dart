part of 'saved_items_controller_library.dart';

extension SavedItemsControllerSyncPart on SavedItemsController {
  Future<void> _bootstrapSavedItems() async {
    final userId = CurrentUserService.instance.effectiveUserId;
    if (userId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.login_required'.tr);
      return;
    }

    try {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        _fetchScholarships(
          userId,
          isLiked: true,
          cacheOnly: true,
          assignResult: false,
        ),
        _fetchScholarships(
          userId,
          isBookmarked: true,
          cacheOnly: true,
          assignResult: false,
        ),
      ]);
      final liked = results[0];
      final bookmarked = results[1];
      if (liked.isNotEmpty || bookmarked.isNotEmpty) {
        likedScholarships.assignAll(liked);
        bookmarkedScholarships.assignAll(bookmarked);
        isLoading.value = false;
        if (SilentRefreshGate.shouldRefresh(
          'scholarships:saved:$userId',
          minInterval: _SavedItemsControllerBase.silentRefreshInterval,
        )) {
          unawaited(fetchSavedItems(silent: true, forceRefresh: true));
        }
        return;
      }
    } catch (_) {}

    await fetchSavedItems();
  }

  Future<void> fetchSavedItems({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final userId = CurrentUserService.instance.effectiveUserId;
    if (userId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.login_required'.tr);
      return;
    }
    final shouldShowLoader =
        !silent && likedScholarships.isEmpty && bookmarkedScholarships.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      await Future.wait([
        _fetchScholarships(
          userId,
          isLiked: true,
          forceRefresh: forceRefresh,
        ),
        _fetchScholarships(
          userId,
          isBookmarked: true,
          forceRefresh: forceRefresh,
        ),
      ]);
      SilentRefreshGate.markRefreshed('scholarships:saved:$userId');
    } finally {
      if (shouldShowLoader ||
          (likedScholarships.isEmpty && bookmarkedScholarships.isEmpty)) {
        isLoading.value = false;
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchScholarships(
    String userId, {
    bool isLiked = false,
    bool isBookmarked = false,
    bool forceRefresh = false,
    bool cacheOnly = false,
    bool assignResult = true,
  }) async {
    try {
      final docs = await _state.scholarshipRepository.fetchByArrayMembershipRaw(
        isLiked ? 'begeniler' : 'kaydedenler',
        userId,
        limit: 50,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

      final scholarships = <Map<String, dynamic>>[];

      final userIds = <String>{};
      for (final data in docs) {
        final userID = data['userID'] as String? ?? '';
        if (userID.isNotEmpty) userIds.add(userID);
      }

      final userDataMap = <String, Map<String, dynamic>>{};
      final users = await _state.userSummaryResolver.resolveMany(
        userIds.toList(growable: false),
        preferCache: true,
        cacheOnly: cacheOnly,
      );
      for (final entry in users.entries) {
        final user = entry.value;
        userDataMap[entry.key] = {
          'avatarUrl': user.avatarUrl,
          'nickname': user.nickname,
          'displayName': user.preferredName,
          'userID': entry.key,
        };
      }

      for (final data in docs) {
        final begeniler = data['begeniler'] as List<dynamic>? ?? [];
        final kaydedenler = data['kaydedenler'] as List<dynamic>? ?? [];

        try {
          final userID = data['userID'] as String? ?? '';
          final userData = userDataMap[userID] ??
              {'avatarUrl': '', 'nickname': '', 'userID': userID};

          scholarships.add({
            'model': IndividualScholarshipsModel.fromJson(data),
            'type': kIndividualScholarshipType,
            'userData': userData,
            'docId': (data['docId'] ?? '').toString(),
            'likesCount': begeniler.length,
            'bookmarksCount': kaydedenler.length,
          });
        } catch (_) {
          AppSnackbar('common.error'.tr, 'common.item_process_failed'.tr);
        }
      }

      if (assignResult) {
        if (isLiked) {
          likedScholarships.value = scholarships;
        } else {
          bookmarkedScholarships.value = scholarships;
        }
      }
      return scholarships;
    } catch (_) {
      AppSnackbar('common.error'.tr, 'common.data_load_failed'.tr);
      return const <Map<String, dynamic>>[];
    }
  }

  Future<void> toggleLike(String docId, String type) async {
    final userId = CurrentUserService.instance.effectiveUserId;
    if (userId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.login_required'.tr);
      return;
    }

    try {
      await _state.scholarshipRepository.toggleLike(
        docId,
        userId: userId,
      );
      await _fetchScholarships(userId, isLiked: true, forceRefresh: true);
    } catch (_) {
      AppSnackbar('common.error'.tr, 'scholarship.like_failed'.tr);
    }
  }

  Future<void> toggleBookmark(String docId, String type) async {
    final userId = CurrentUserService.instance.effectiveUserId;
    if (userId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.login_required'.tr);
      return;
    }

    try {
      await _state.scholarshipRepository.toggleBookmark(
        docId,
        userId: userId,
      );
      await _fetchScholarships(
        userId,
        isBookmarked: true,
        forceRefresh: true,
      );
    } catch (_) {
      AppSnackbar('common.error'.tr, 'scholarship.bookmark_failed'.tr);
    }
  }

  void onTabChanged(int index) {
    selectedTabIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeInOut,
    );
  }
}
