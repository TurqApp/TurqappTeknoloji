part of 'story_row_controller.dart';

class StoryRowController extends GetxController {
  final _state = _StoryRowControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleStoryRowInit(this);
  }
}
