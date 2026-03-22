part of 'tutoring_controller.dart';

extension TutoringControllerSearchPart on TutoringController {
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
      final result = await _tutoringSnapshotRepository.search(
        userId: CurrentUserService.instance.effectiveUserId,
        query: normalized,
        limit: 40,
        forceSync: true,
      );
      if (token != _searchToken || searchQuery.value.trim() != normalized) {
        return;
      }
      final results = result.data ?? const <TutoringModel>[];
      if (token != _searchToken || searchQuery.value.trim() != normalized) {
        return;
      }
      final nextResults = _applyPersonalization(results);
      if (!_sameTutoringEntries(searchResults, nextResults)) {
        searchResults.assignAll(nextResults);
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

  double _personalizedScore(TutoringModel t) {
    double score = 0;
    if (t.verified == true) score += 3;
    if (t.averageRating != null) {
      score += (t.averageRating!.toDouble() / 5.0) * 2.0;
    }
    try {
      final userCity = CurrentUserService.instance.currentUser?.city;
      if (userCity != null && userCity.isNotEmpty && t.sehir == userCity) {
        score += 2;
      }
    } catch (_) {}
    return score;
  }

  List<TutoringModel> _applyPersonalization(List<TutoringModel> list) {
    final sorted = List<TutoringModel>.from(list);
    sorted.sort((a, b) {
      final scoreA = _personalizedScore(a);
      final scoreB = _personalizedScore(b);
      if (scoreA != scoreB) return scoreB.compareTo(scoreA);
      return 0;
    });
    return sorted;
  }

  Future<bool> toggleFavorite(
    String docId,
    String userId,
    bool isFavorite,
  ) async {
    final tutoringIndex = tutoringList.indexWhere((t) => t.docID == docId);
    final currentTutoring =
        tutoringIndex == -1 ? null : tutoringList[tutoringIndex];
    final oldFavorites = currentTutoring == null
        ? <String>[]
        : List<String>.from(currentTutoring.favorites);
    final nextFavorites = List<String>.from(oldFavorites);
    if (isFavorite) {
      nextFavorites.remove(userId);
    } else if (!nextFavorites.contains(userId)) {
      nextFavorites.add(userId);
    }

    if (currentTutoring != null) {
      tutoringList[tutoringIndex] = currentTutoring.copyWith(
        favorites: nextFavorites,
      );
      tutoringList.refresh();
    }

    try {
      await _tutoringRepository.toggleFavorite(
        docId: docId,
        userId: userId,
        isFavorite: isFavorite,
      );
      return true;
    } catch (_) {
      if (currentTutoring != null) {
        tutoringList[tutoringIndex] = currentTutoring.copyWith(
          favorites: oldFavorites,
        );
        tutoringList.refresh();
      }
      return false;
    }
  }
}
