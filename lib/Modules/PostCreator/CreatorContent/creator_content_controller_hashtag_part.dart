part of 'creator_content_controller.dart';

extension _CreatorContentControllerHashtagPart on CreatorContentController {
  static const int _hashtagSuggestionLimit = 8;

  Future<void> _performEnsureTrendingHashtagsLoaded() async {
    if (trendingHashtags.isNotEmpty || hashtagSuggestionsLoading.value) {
      return;
    }
    hashtagSuggestionsLoading.value = true;
    try {
      final items = await _topTagsRepository.fetchTrendingTags(
        resultLimit: 20,
        preferCache: true,
        forceRefresh: false,
      );
      trendingHashtags.assignAll(items);
      _refreshHashtagSuggestions();
    } catch (_) {
      trendingHashtags.clear();
      hashtagSuggestions.clear();
      showHashtagSuggestions.value = false;
    } finally {
      hashtagSuggestionsLoading.value = false;
    }
  }

  void _performRefreshHashtagSuggestionsFromCursor() {
    final value = textEdit.value;
    final selection = value.selection;
    if (!selection.isValid) {
      activeHashtagQuery.value = '';
      hashtagSuggestions.clear();
      showHashtagSuggestions.value = false;
      return;
    }
    final cursor =
        selection.baseOffset >= 0 ? selection.baseOffset : value.text.length;
    final query = extractComposerHashtagQuery(value.text, cursor);
    if (query == null) {
      activeHashtagQuery.value = '';
      hashtagSuggestions.clear();
      showHashtagSuggestions.value = false;
      return;
    }
    activeHashtagQuery.value = query;
    showHashtagSuggestions.value = true;
    _refreshHashtagSuggestions();
    unawaited(ensureTrendingHashtagsLoaded());
  }

  void _performApplyTrendingHashtagSelection(HashtagModel model) {
    final currentValue = textEdit.value;
    final selection = currentValue.selection;
    final cursor = selection.isValid && selection.baseOffset >= 0
        ? selection.baseOffset
        : currentValue.text.length;
    final result = applyComposerHashtagSelection(
      text: currentValue.text,
      cursorOffset: cursor,
      hashtag: model.hashtag,
    );
    textEdit.value = currentValue.copyWith(
      text: result.text,
      selection: TextSelection.collapsed(offset: result.cursorOffset),
      composing: TextRange.empty,
    );
    textChanged.value = result.text.trim().isNotEmpty;
    activeHashtagQuery.value = '';
    hashtagSuggestions.clear();
    showHashtagSuggestions.value = false;
  }

  void _refreshHashtagSuggestions() {
    final query = normalizeSearchText(activeHashtagQuery.value);
    final prefixMatches = <HashtagModel>[];
    final containsMatches = <HashtagModel>[];
    final seen = <String>{};

    for (final item in trendingHashtags) {
      final raw = item.hashtag.trim();
      if (raw.isEmpty) continue;
      final key = raw.toLowerCase();
      if (!seen.add(key)) continue;
      final normalized = normalizeSearchText(raw);
      if (query.isEmpty || normalized.startsWith(query)) {
        prefixMatches.add(item);
      } else if (normalized.contains(query)) {
        containsMatches.add(item);
      }
    }

    hashtagSuggestions.assignAll(
      <HashtagModel>[
        ...prefixMatches,
        ...containsMatches,
      ].take(_hashtagSuggestionLimit),
    );
  }
}
