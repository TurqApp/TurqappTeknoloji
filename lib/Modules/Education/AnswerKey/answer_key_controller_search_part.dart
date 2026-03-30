part of 'answer_key_controller.dart';

extension AnswerKeyControllerSearchPart on AnswerKeyController {
  String _listingSelectionKeyFor(String uid) =>
      '${AnswerKeyController._listingSelectionPrefKeyPrefix}_$uid';

  Future<void> _restoreListingSelection() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      listingSelection.value = 1;
      listingSelectionReady.value = true;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_listingSelectionKeyFor(uid));
      listingSelection.value = stored == null ? 1 : (stored == 1 ? 1 : 0);
    } catch (_) {
      listingSelection.value = 1;
    } finally {
      listingSelectionReady.value = true;
    }
  }

  Future<void> _persistListingSelection() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _listingSelectionKeyFor(uid),
        listingSelection.value == 1 ? 1 : 0,
      );
    } catch (_) {}
  }

  void _toggleListingSelectionValue() {
    listingSelection.value = listingSelection.value == 0 ? 1 : 0;
    unawaited(_persistListingSelection());
  }

  void setSearchQuery(String query) {
    searchQuery.value = query.trim();
    _searchDebounce?.cancel();
    if (!hasActiveSearch) {
      isSearchLoading.value = false;
      searchResults.clear();
      _searchToken++;
      return;
    }

    final token = ++_searchToken;
    isSearchLoading.value = true;
    _searchDebounce = Timer(const Duration(milliseconds: 150), () async {
      await _searchFromTypesense(searchQuery.value, token);
    });
  }

  Future<void> _searchFromTypesense(String query, int token) async {
    final normalized = query.trim();
    try {
      final resource = await _answerKeySnapshotRepository.search(
        query: normalized,
        userId: CurrentUserService.instance.effectiveUserId,
        limit: ReadBudgetRegistry.answerKeySearchInitialLimit,
        forceSync: true,
      );
      if (token != _searchToken || searchQuery.value.trim() != normalized) {
        return;
      }

      final results = resource.data ?? const <BookletModel>[];
      if (token != _searchToken || searchQuery.value.trim() != normalized) {
        return;
      }
      if (!_sameBookletEntries(searchResults, results)) {
        searchResults.assignAll(results);
      }
    } catch (_) {
      if (token == _searchToken) {
        searchResults.clear();
      }
    } finally {
      if (token == _searchToken) {
        isSearchLoading.value = false;
      }
    }
  }
}
