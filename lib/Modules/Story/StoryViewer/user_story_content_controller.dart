import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Models/story_comment_model.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/StoryComments/story_comments.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'StoryLikes/story_likes.dart';
import 'StorySeens/story_seens.dart';

part 'user_story_content_controller_facade_part.dart';
part 'user_story_content_controller_runtime_part.dart';

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

  // Reaction emoji support
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
