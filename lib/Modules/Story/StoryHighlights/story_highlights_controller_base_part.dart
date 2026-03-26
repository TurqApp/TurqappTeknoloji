part of 'story_highlights_controller_library.dart';

abstract class _StoryHighlightsControllerBase extends GetxController {
  _StoryHighlightsControllerBase({required String userId})
      : _state = _StoryHighlightsControllerState(userId: userId);

  final _StoryHighlightsControllerState _state;
}
