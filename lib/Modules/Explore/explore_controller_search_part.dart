part of 'explore_controller.dart';

extension ExploreControllerSearchPart on ExploreController {
  void _performResetSurfaceForTabTransition() {
    _performResetSearchToDefault();
    floodsVisibleIndex.value = -1;
    lastFloodVisibleIndex = null;
    _pendingFloodDocId = null;
    showScrollToTop.value = false;

    void resetNow(ScrollController controller) {
      if (!controller.hasClients) return;
      try {
        controller.jumpTo(0);
      } catch (_) {}
    }

    for (final controller in <ScrollController>[
      exploreScroll,
      videoScroll,
      photoScroll,
      floodsScroll,
    ]) {
      resetNow(controller);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in <ScrollController>[
        exploreScroll,
        videoScroll,
        photoScroll,
        floodsScroll,
      ]) {
        resetNow(controller);
      }
    });
  }

  Future<dynamic> _performCallTypesenseCallable(
    String callableName,
    Map<String, dynamic> payload,
  ) async {
    final targets = <FirebaseFunctions>[
      FirebaseFunctions.instance,
      FirebaseFunctions.instanceFor(region: 'us-central1'),
      FirebaseFunctions.instanceFor(region: 'europe-west1'),
    ];

    Object? lastError;
    for (final fn in targets) {
      try {
        final result = await fn.httpsCallable(callableName).call(payload);
        return result.data;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('typesense_callable_failed');
  }

  Future<List<OgrenciModel>> _performFilterPendingOrDeletedUsers(
    List<OgrenciModel> users,
  ) async {
    if (users.isEmpty) return users;
    final blocked = <String>{};
    final ids = users.map((e) => e.userID).where((e) => e.isNotEmpty).toList();

    final profiles = await _userCache.getProfiles(
      ids,
      preferCache: true,
      cacheOnly: !ContentPolicy.isConnected,
    );
    for (final entry in profiles.entries) {
      final data = entry.value;
      if (isDeactivatedAccount(
        accountStatus: data['accountStatus'],
        isDeleted: data['isDeleted'],
      )) {
        blocked.add(entry.key);
      }
    }

    return users.where((user) => !blocked.contains(user.userID)).toList();
  }

  void _performOnSearchChanged(String value) {
    searchText.value = value;
    _searchDebounce?.cancel();

    final normalized = value.trim();
    if (normalized.isEmpty) {
      _searchRequestId++;
      _clearSearchResults();
      return;
    }

    isSearchMode.value = true;
    _searchDebounce = Timer(_searchDebounceDuration, () {
      unawaited(search(normalized));
    });
  }

  void _performClearSearchResults() {
    searchedList.clear();
    searchedHashtags.clear();
    searchedTags.clear();
    showAllRecent.value = false;
  }

  Future<void> _performSearch(String query) async {
    final nick = query.trim();
    final currentUserId = CurrentUserService.instance.effectiveUserId;
    final requestId = ++_searchRequestId;
    if (nick.isEmpty) {
      _clearSearchResults();
      return;
    }

    try {
      final results = await Future.wait([
        _callTypesenseCallable('f15_searchTagsCallable', {
          'q': nick,
          'limit': 20,
          'page': 1,
        }),
        if (nick.length >= 2)
          _callTypesenseCallable('f15_searchUsersCallable', {
            'q': nick,
            'limit': 20,
            'page': 1,
          })
        else
          Future.value({'hits': []}),
      ]);

      if (requestId != _searchRequestId || searchText.value.trim() != nick) {
        return;
      }

      final tagData = (results[0] as Map?) ?? {};
      final userData = (results[1] as Map?) ?? {};

      final rawTagHits = (tagData['hits'] as List?) ?? const [];
      final rawUserHits = (userData['hits'] as List?) ?? const [];

      final allTagHits = rawTagHits
          .whereType<Map>()
          .map((entry) {
            final tag = (entry['tag'] ?? '').toString().trim();
            final count = (entry['count'] as num?) ?? 0;
            final hasHashtag = entry['hasHashtag'] == true;
            return HashtagModel(tag, count, hasHashtag: hasHashtag);
          })
          .where((entry) => entry.hashtag.isNotEmpty)
          .toList();

      searchedHashtags.value =
          allTagHits.where((entry) => entry.hasHashtag).take(3).toList();
      searchedTags.value =
          allTagHits.where((entry) => !entry.hasHashtag).take(3).toList();

      final users = <OgrenciModel>[];
      for (final row in rawUserHits.whereType<Map>()) {
        final uid = (row['id'] ??
                row['userID'] ??
                row['uid'] ??
                row['docID'] ??
                row['userId'] ??
                '')
            .toString()
            .trim();
        if (uid.isEmpty || uid == currentUserId) continue;
        users.add(
          OgrenciModel(
            userID: uid,
            nickname: (row['nickname'] ?? '').toString(),
            firstName: ((row['displayName'] ?? '').toString().trim().isNotEmpty
                    ? row['displayName']
                    : row['nickname'] ?? '')
                .toString(),
            lastName: '',
            avatarUrl: (row['avatarUrl'] ?? '').toString(),
          ),
        );
      }

      final filteredUsers = await _filterPendingOrDeletedUsers(users);
      if (requestId != _searchRequestId || searchText.value.trim() != nick) {
        return;
      }
      searchedList.value = filteredUsers;
    } catch (_) {
      if (requestId != _searchRequestId || searchText.value.trim() != nick) {
        return;
      }
      _clearSearchResults();
    }
  }

  void _performResetSearchToDefault() {
    final preservedTabIndex = _preserveTabIndexOnNextReturn;
    _preserveTabIndexOnNextReturn = null;
    _searchDebounce?.cancel();
    _searchRequestId++;
    searchFocus.unfocus();
    searchController.clear();
    searchText.value = '';
    _clearSearchResults();
    isKeyboardOpen.value = false;
    isSearchMode.value = false;
    selection.value = preservedTabIndex ?? 0;
    if (pageController.hasClients) {
      pageController.jumpToPage(preservedTabIndex ?? 0);
    }
  }
}
