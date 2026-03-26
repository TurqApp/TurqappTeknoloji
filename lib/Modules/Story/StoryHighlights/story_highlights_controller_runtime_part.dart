part of 'story_highlights_controller_library.dart';

extension _StoryHighlightsControllerRuntimeX on StoryHighlightsController {
  Future<void> _bootstrapHighlights() async {
    final cached = await _repository.getHighlights(
      userId,
      preferCache: true,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      highlights.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'story:highlights:$userId',
        minInterval: StoryHighlightsController._silentRefreshInterval,
      )) {
        unawaited(loadHighlights(silent: true, forceRefresh: true));
      }
      unawaited(_hydrateMissingCoverUrls());
      return;
    }
    await loadHighlights();
  }

  Future<void> loadHighlights({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    try {
      if (!silent) {
        isLoading.value = true;
      }
      final loaded = await _repository.getHighlights(
        userId,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      highlights.assignAll(loaded);
      SilentRefreshGate.markRefreshed('story:highlights:$userId');
      await _hydrateMissingCoverUrls();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}
