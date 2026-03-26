part of 'story_maker_controller.dart';

class StoryMakerController extends GetxController {
  final _state = _StoryMakerControllerState();

  StoryMakerController() {
    _configureStoryMakerAudioPlayer(_audioPlayer);
  }

  @override
  void onInit() {
    super.onInit();
    _handleStoryMakerOnInit(this);
  }

  @override
  void onClose() {
    _handleStoryMakerOnClose(this);
    super.onClose();
  }
}
