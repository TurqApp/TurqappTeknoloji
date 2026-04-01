part of 'story_highlights_repository.dart';

extension _StoryHighlightsRepositoryLifecyclePart on StoryHighlightsRepository {
  void handleOnInit() {
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }
}
