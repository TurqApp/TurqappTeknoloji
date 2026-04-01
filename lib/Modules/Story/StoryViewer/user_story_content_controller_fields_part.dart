part of 'user_story_content_controller_library.dart';

UserStoryContentController _ensureUserStoryContentController({
  required String tag,
  required String storyID,
  required String nickname,
  required bool isMyStory,
  bool permanent = false,
}) {
  final existing = _maybeFindUserStoryContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    UserStoryContentController(
      storyID: storyID,
      nickname: nickname,
      isMyStory: isMyStory,
    ),
    tag: tag,
    permanent: permanent,
  );
}

UserStoryContentController? _maybeFindUserStoryContentController({
  required String tag,
}) {
  final isRegistered = Get.isRegistered<UserStoryContentController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<UserStoryContentController>(tag: tag);
}

class _UserStoryContentControllerState {
  _UserStoryContentControllerState(this.storyID, this.nickname, this.isMyStory);

  final String storyID;
  final String nickname;
  final bool isMyStory;
  final RxList<StoryCommentModel> comments = <StoryCommentModel>[].obs;
  final RxInt likeCount = 0.obs;
  final RxBool isLikedMe = false.obs;
  final StoryRepository storyRepository = StoryRepository.ensure();
  final CurrentUserService userService = CurrentUserService.instance;
  final RxMap<String, int> reactionCounts = <String, int>{}.obs;
  final RxString myReaction = ''.obs;
}

extension UserStoryContentControllerFieldsPart on UserStoryContentController {
  String get storyID => _state.storyID;
  String get nickname => _state.nickname;
  bool get isMyStory => _state.isMyStory;
  RxList<StoryCommentModel> get comments => _state.comments;
  RxInt get likeCount => _state.likeCount;
  RxBool get isLikedMe => _state.isLikedMe;
  StoryRepository get _storyRepository => _state.storyRepository;
  CurrentUserService get _userService => _state.userService;
  String get _currentUid => _userService.effectiveUserId;
  RxMap<String, int> get reactionCounts => _state.reactionCounts;
  RxString get myReaction => _state.myReaction;
}
