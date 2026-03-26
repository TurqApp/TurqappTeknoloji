part of 'user_story_content_controller.dart';

class UserStoryContentController extends GetxController {
  static UserStoryContentController ensure({
    required String tag,
    required String storyID,
    required String nickname,
    required bool isMyStory,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
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

  static UserStoryContentController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<UserStoryContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<UserStoryContentController>(tag: tag);
  }

  String storyID;
  String nickname;
  bool isMyStory;
  UserStoryContentController({
    required this.storyID,
    required this.nickname,
    required this.isMyStory,
  });
  List<StoryCommentModel> comments = <StoryCommentModel>[].obs;
  var likeCount = 0.obs;
  var isLikedMe = false.obs;
  final StoryRepository _storyRepository = StoryRepository.ensure();
  final CurrentUserService _userService = CurrentUserService.instance;
  String get _currentUid => _userService.effectiveUserId;

  static const List<String> reactionEmojis = [
    '❤️',
    '😂',
    '😮',
    '😢',
    '🔥',
    '👏'
  ];
  final RxMap<String, int> reactionCounts = <String, int>{}.obs;
  final RxString myReaction = ''.obs;
}
