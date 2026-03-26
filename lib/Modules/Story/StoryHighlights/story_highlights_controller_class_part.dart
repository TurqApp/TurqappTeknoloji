part of 'story_highlights_controller.dart';

class StoryHighlightsController extends GetxController {
  static StoryHighlightsController ensure({
    required String userId,
    required String tag,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(StoryHighlightsController(userId: userId), tag: tag);
  }

  static StoryHighlightsController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<StoryHighlightsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<StoryHighlightsController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final String userId;
  StoryHighlightsController({required this.userId});
  final StoryHighlightsRepository _repository =
      StoryHighlightsRepository.ensure();
  final StoryRepository _storyRepository = StoryRepository.ensure();
  final CurrentUserService _userService = CurrentUserService.instance;
  String get _ownerUid => userId.trim();

  bool get _canMutateOwnedHighlights {
    final ownerUid = _ownerUid;
    if (ownerUid.isEmpty) return false;
    final authUid = _userService.authUserId.trim();
    if (authUid.isEmpty) return true;
    return authUid == ownerUid;
  }

  RxList<StoryHighlightModel> highlights = <StoryHighlightModel>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_StoryHighlightsControllerRuntimeX(this)._bootstrapHighlights());
  }
}
