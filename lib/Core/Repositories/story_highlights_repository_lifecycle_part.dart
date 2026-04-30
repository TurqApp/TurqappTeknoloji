part of 'story_highlights_repository.dart';

extension _StoryHighlightsRepositoryLifecyclePart on StoryHighlightsRepository {
  void handleOnInit() {
    ensureLocalPreferenceRepository().sharedPreferences().then((prefs) {
      _prefs = prefs;
    });
  }
}
