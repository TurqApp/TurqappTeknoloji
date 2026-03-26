part of 'story_highlights_controller_library.dart';

class StoryHighlightsController extends _StoryHighlightsControllerBase {
  StoryHighlightsController({required super.userId});

  @override
  void onInit() {
    super.onInit();
    unawaited(_StoryHighlightsControllerRuntimeX(this)._bootstrapHighlights());
  }
}
