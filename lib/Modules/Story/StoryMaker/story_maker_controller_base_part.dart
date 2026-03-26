part of 'story_maker_controller.dart';

abstract class _StoryMakerControllerBase extends GetxController {
  _StoryMakerControllerBase() : _state = _StoryMakerControllerState() {
    _configureStoryMakerAudioPlayer(_state.audioPlayer);
  }

  final _StoryMakerControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handleStoryMakerOnInit(this as StoryMakerController);
  }

  @override
  void onClose() {
    _handleStoryMakerOnClose(this as StoryMakerController);
    super.onClose();
  }
}
