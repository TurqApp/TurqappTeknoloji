part of 'saved_items_controller_library.dart';

extension SavedItemsControllerSyncPart on SavedItemsController {
  void configureView({
    required int initialTabIndex,
    required bool showOnlySelectedTab,
  }) {
    _state.showOnlySelectedTab = showOnlySelectedTab;
    _state.configured = true;
    setInitialTab(initialTabIndex);
    unawaited(_bootstrapSavedItems());
  }

  Future<void> _bootstrapSavedItems() async {
    final userId = CurrentUserService.instance.effectiveUserId;
    if (userId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.login_required'.tr);
      return;
    }

    try {
      if (showOnlySelectedTab) {
        final memoryCached = _readSelectedScreenCache(userId);
        if (memoryCached != null) {
          _assignSelectedResult(memoryCached);
          isLoading.value = false;
          if (SilentRefreshGate.shouldRefresh(
            _refreshGateKey(userId),
            minInterval: _SavedItemsControllerBase.silentRefreshInterval,
          )) {
            unawaited(fetchSavedItems(silent: true, forceRefresh: true));
          }
          return;
        }

        final cached = await _fetchScholarships(
          userId,
          isLiked: selectedTabIndex.value == 1,
          isBookmarked: selectedTabIndex.value == 0,
          cacheOnly: true,
          assignResult: false,
        );
        if (cached.isNotEmpty) {
          _assignSelectedResult(cached);
          _storeSelectedScreenCache(userId, cached);
          isLoading.value = false;
          if (SilentRefreshGate.shouldRefresh(
            _refreshGateKey(userId),
            minInterval: _SavedItemsControllerBase.silentRefreshInterval,
          )) {
            unawaited(fetchSavedItems(silent: true, forceRefresh: true));
          }
          return;
        }
      } else {
        final cachedLiked = _readScreenCache(
          _screenCacheKey(userId, isLiked: true),
        );
        final cachedBookmarked = _readScreenCache(
          _screenCacheKey(userId, isLiked: false),
        );
        if (cachedLiked != null || cachedBookmarked != null) {
          likedScholarships.assignAll(cachedLiked ?? const []);
          bookmarkedScholarships.assignAll(cachedBookmarked ?? const []);
          isLoading.value = false;
          if (SilentRefreshGate.shouldRefresh(
            _refreshGateKey(userId),
            minInterval: _SavedItemsControllerBase.silentRefreshInterval,
          )) {
            unawaited(fetchSavedItems(silent: true, forceRefresh: true));
          }
          return;
        }

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
        if (liked.isEmpty && bookmarked.isEmpty) {
          throw StateError('saved_items_cache_empty');
        }
        likedScholarships.assignAll(liked);
        bookmarkedScholarships.assignAll(bookmarked);
        _storeScreenCache(_screenCacheKey(userId, isLiked: true), liked);
        _storeScreenCache(
          _screenCacheKey(userId, isLiked: false),
          bookmarked,
        );
        isLoading.value = false;
        if (SilentRefreshGate.shouldRefresh(
          _refreshGateKey(userId),
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
    final shouldShowLoader = !silent && _selectedListIsEmpty();
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      if (showOnlySelectedTab) {
        final items = await _fetchScholarships(
          userId,
          isLiked: selectedTabIndex.value == 1,
          isBookmarked: selectedTabIndex.value == 0,
          forceRefresh: forceRefresh,
          assignResult: false,
          showError: !silent,
        );
        if (!silent || items.isNotEmpty || _selectedListIsEmpty()) {
          _assignSelectedResult(items);
          _storeSelectedScreenCache(userId, items);
        } else {
          debugPrint(
            '[SavedItemsFetch] keep_existing_selected_after_empty_silent '
            'tab=${selectedTabIndex.value}',
          );
        }
      } else {
        final results = await Future.wait([
          _fetchScholarships(
            userId,
            isLiked: true,
            forceRefresh: forceRefresh,
            assignResult: false,
            showError: !silent,
          ),
          _fetchScholarships(
            userId,
            isBookmarked: true,
            forceRefresh: forceRefresh,
            assignResult: false,
            showError: !silent,
          ),
        ]);
        final liked = results[0];
        final bookmarked = results[1];
        if (!silent || liked.isNotEmpty || likedScholarships.isEmpty) {
          likedScholarships.assignAll(liked);
          _storeScreenCache(_screenCacheKey(userId, isLiked: true), liked);
        } else {
          debugPrint(
              '[SavedItemsFetch] keep_existing_liked_after_empty_silent');
        }
        if (!silent ||
            bookmarked.isNotEmpty ||
            bookmarkedScholarships.isEmpty) {
          bookmarkedScholarships.assignAll(bookmarked);
          _storeScreenCache(
            _screenCacheKey(userId, isLiked: false),
            bookmarked,
          );
        } else {
          debugPrint(
            '[SavedItemsFetch] keep_existing_bookmarked_after_empty_silent',
          );
        }
      }
      SilentRefreshGate.markRefreshed(_refreshGateKey(userId));
    } finally {
      if (shouldShowLoader || _selectedListIsEmpty()) {
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
    bool showError = true,
  }) async {
    try {
      final docs = await _state.scholarshipRepository.fetchByArrayMembershipRaw(
        isLiked ? 'begeniler' : 'kaydedenler',
        userId,
        limit: ReadBudgetRegistry.scholarshipSavedInitialLimit,
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
      try {
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
      } catch (error, stackTrace) {
        debugPrint(
          '[SavedItemsFetch] user_summary_failed '
          'liked=$isLiked bookmarked=$isBookmarked error=$error',
        );
        debugPrintStack(stackTrace: stackTrace);
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

      final mergedScholarships = applySavedItemsInteractionOverridesForUser(
        userId: userId,
        isLiked: isLiked,
        items: scholarships,
      );

      if (assignResult) {
        if (isLiked) {
          likedScholarships.value = mergedScholarships;
        } else {
          bookmarkedScholarships.value = mergedScholarships;
        }
      }
      return mergedScholarships;
    } catch (error, stackTrace) {
      debugPrint(
        '[SavedItemsFetch] failed liked=$isLiked bookmarked=$isBookmarked '
        'cacheOnly=$cacheOnly forceRefresh=$forceRefresh error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (showError) {
        AppSnackbar('common.error'.tr, 'scholarship.data_load_failed'.tr);
      }
      return const <Map<String, dynamic>>[];
    }
  }

  Future<void> toggleLike(String docId, String type) async {
    final userId = CurrentUserService.instance.effectiveUserId;
    if (userId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.login_required'.tr);
      return;
    }

    final previous = _cloneSavedItemList(likedScholarships);
    try {
      debugPrint(
        '[SavedItems] toggle_like start docId=$docId before=${likedScholarships.length}',
      );
      invalidateSavedItemsScreenCacheForUser(userId, isLiked: true);
      likedScholarships.removeWhere((item) => item['docId'] == docId);
      _storeScreenCache(
        _screenCacheKey(userId, isLiked: true),
        likedScholarships,
      );
      await _state.scholarshipRepository.toggleLike(
        docId,
        userId: userId,
      );
      final items = await _fetchScholarships(
        userId,
        isLiked: true,
        forceRefresh: true,
      );
      _storeScreenCache(_screenCacheKey(userId, isLiked: true), items);
      debugPrint(
        '[SavedItems] toggle_like done docId=$docId after=${items.length}',
      );
    } catch (_) {
      likedScholarships.assignAll(previous);
      _storeScreenCache(_screenCacheKey(userId, isLiked: true), previous);
      AppSnackbar('common.error'.tr, 'scholarship.like_failed'.tr);
    }
  }

  Future<void> toggleBookmark(String docId, String type) async {
    final userId = CurrentUserService.instance.effectiveUserId;
    if (userId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.login_required'.tr);
      return;
    }

    final previous = _cloneSavedItemList(bookmarkedScholarships);
    try {
      debugPrint(
        '[SavedItems] toggle_bookmark start docId=$docId before=${bookmarkedScholarships.length}',
      );
      invalidateSavedItemsScreenCacheForUser(userId, isLiked: false);
      bookmarkedScholarships.removeWhere((item) => item['docId'] == docId);
      _storeScreenCache(
        _screenCacheKey(userId, isLiked: false),
        bookmarkedScholarships,
      );
      await _state.scholarshipRepository.toggleBookmark(
        docId,
        userId: userId,
      );
      final items = await _fetchScholarships(
        userId,
        isBookmarked: true,
        forceRefresh: true,
      );
      _storeScreenCache(_screenCacheKey(userId, isLiked: false), items);
      debugPrint(
        '[SavedItems] toggle_bookmark done docId=$docId after=${items.length}',
      );
    } catch (_) {
      bookmarkedScholarships.assignAll(previous);
      _storeScreenCache(_screenCacheKey(userId, isLiked: false), previous);
      AppSnackbar('common.error'.tr, 'scholarship.bookmark_failed'.tr);
    }
  }

  void setInitialTab(int index) {
    final safeIndex = index.clamp(0, 1);
    selectedTabIndex.value = safeIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!pageController.hasClients) return;
      pageController.jumpToPage(safeIndex);
    });
  }

  void onTabChanged(int index) {
    final safeIndex = index.clamp(0, 1);
    selectedTabIndex.value = safeIndex;
    if (!pageController.hasClients) return;
    pageController.animateToPage(
      safeIndex,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeInOut,
    );
  }

  void _assignSelectedResult(List<Map<String, dynamic>> items) {
    if (selectedTabIndex.value == 1) {
      likedScholarships.assignAll(items);
    } else {
      bookmarkedScholarships.assignAll(items);
    }
  }

  bool _selectedListIsEmpty() {
    if (showOnlySelectedTab) {
      return selectedTabIndex.value == 1
          ? likedScholarships.isEmpty
          : bookmarkedScholarships.isEmpty;
    }
    return likedScholarships.isEmpty && bookmarkedScholarships.isEmpty;
  }

  String _refreshGateKey(String userId) {
    if (!showOnlySelectedTab) return 'scholarships:saved:$userId';
    final kind = selectedTabIndex.value == 1 ? 'liked' : 'bookmarked';
    return 'scholarships:saved:$kind:$userId';
  }

  List<Map<String, dynamic>>? _readSelectedScreenCache(String userId) {
    return _readScreenCache(
      _screenCacheKey(
        userId,
        isLiked: selectedTabIndex.value == 1,
      ),
    );
  }

  List<Map<String, dynamic>>? _readScreenCache(String key) {
    final cached = _SavedItemsControllerBase._screenCache[key];
    if (cached == null) return null;
    final age = DateTime.now().difference(cached.cachedAt);
    if (age > _SavedItemsControllerBase.silentRefreshInterval) {
      _SavedItemsControllerBase._screenCache.remove(key);
      return null;
    }
    return _cloneSavedItemList(cached.items);
  }

  void _storeSelectedScreenCache(
    String userId,
    List<Map<String, dynamic>> items,
  ) {
    _storeScreenCache(
      _screenCacheKey(
        userId,
        isLiked: selectedTabIndex.value == 1,
      ),
      items,
    );
  }

  void _storeScreenCache(String key, List<Map<String, dynamic>> items) {
    _SavedItemsControllerBase._screenCache[key] = _CachedSavedItemsList(
      items: _cloneSavedItemList(items),
      cachedAt: DateTime.now(),
    );
  }

  String _screenCacheKey(String userId, {required bool isLiked}) {
    final kind = isLiked ? 'liked' : 'bookmarked';
    return '$kind:$userId';
  }

  List<Map<String, dynamic>> _cloneSavedItemList(
    List<Map<String, dynamic>> items,
  ) {
    return items
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
