part of 'story_maker_controller.dart';

class StoryMakerController extends GetxController {
  static StoryMakerController ensure({
    String? tag,
    bool permanent = false,
  }) =>
      _ensureStoryMakerController(tag: tag, permanent: permanent);

  static StoryMakerController? maybeFind({String? tag}) =>
      _maybeFindStoryMakerController(tag: tag);

  static List<String> get supportedMediaLookPresets =>
      _storyMakerSupportedMediaLookPresetsFacade();
  final _state = _StoryMakerControllerState();
  static RxBool get isUploadingStory => _storyMakerIsUploadingStoryFacade();

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
