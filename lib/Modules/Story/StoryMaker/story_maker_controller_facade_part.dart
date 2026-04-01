part of 'story_maker_controller.dart';

StoryMakerController ensureStoryMakerController({
  String? tag,
  bool permanent = false,
}) =>
    _ensureStoryMakerController(tag: tag, permanent: permanent);

StoryMakerController? maybeFindStoryMakerController({String? tag}) =>
    _maybeFindStoryMakerController(tag: tag);

List<String> get storyMakerSupportedMediaLookPresets =>
    _storyMakerSupportedMediaLookPresetsFacade();

RxBool get storyMakerIsUploadingStory => _storyMakerIsUploadingStoryFacade();

StoryMakerController _ensureStoryMakerController({
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindStoryMakerController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    StoryMakerController(),
    tag: tag,
    permanent: permanent,
  );
}

StoryMakerController? _maybeFindStoryMakerController({String? tag}) =>
    Get.isRegistered<StoryMakerController>(tag: tag)
        ? Get.find<StoryMakerController>(tag: tag)
        : null;

List<String> _storyMakerSupportedMediaLookPresetsFacade() =>
    _storyMakerSupportedMediaLookPresets;

RxBool _storyMakerIsUploadingStoryFacade() => _storyMakerIsUploadingStory;
