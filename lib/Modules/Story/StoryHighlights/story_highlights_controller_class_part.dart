part of 'story_highlights_controller_library.dart';

class StoryHighlightsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  StoryHighlightsController({required String userId})
      : _state = _StoryHighlightsControllerState(userId: userId);

  final _StoryHighlightsControllerState _state;

  @override
  void onInit() {
    super.onInit();
    unawaited(_StoryHighlightsControllerRuntimeX(this)._bootstrapHighlights());
  }
}
