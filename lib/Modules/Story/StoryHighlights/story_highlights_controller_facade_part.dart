part of 'story_highlights_controller.dart';

extension StoryHighlightsControllerFacadePart on StoryHighlightsController {
  Future<void> loadHighlights({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _StoryHighlightsControllerRuntimeX(this).loadHighlights(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<StoryHighlightModel?> createHighlight({
    required String title,
    required List<String> storyIds,
    String coverUrl = '',
  }) =>
      _StoryHighlightsControllerActionsX(this).createHighlight(
        title: title,
        storyIds: storyIds,
        coverUrl: coverUrl,
      );

  Future<void> addStoryToHighlight(String highlightId, String storyId) =>
      _StoryHighlightsControllerActionsX(this).addStoryToHighlight(
        highlightId,
        storyId,
      );

  Future<void> deleteHighlight(String highlightId) =>
      _StoryHighlightsControllerActionsX(this).deleteHighlight(highlightId);

  Future<void> updateHighlight(
    String highlightId,
    String title,
    String coverUrl,
  ) =>
      _StoryHighlightsControllerActionsX(this).updateHighlight(
        highlightId,
        title,
        coverUrl,
      );
}
