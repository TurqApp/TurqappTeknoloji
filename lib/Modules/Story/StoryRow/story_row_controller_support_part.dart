part of 'story_row_controller.dart';

StoryRowController? maybeFindStoryRowController() {
  final isRegistered = Get.isRegistered<StoryRowController>();
  if (!isRegistered) return null;
  return Get.find<StoryRowController>();
}

StoryRowController ensureStoryRowController() {
  final existing = maybeFindStoryRowController();
  if (existing != null) return existing;
  return Get.put(StoryRowController());
}

Future<void> refreshStoryRowGlobally() => _refreshStoryRowGlobally();

Future<void> _refreshStoryRowGlobally() async {
  try {
    final controller = maybeFindStoryRowController();
    if (controller == null) return;
    await controller.loadStories();
  } catch (e) {
    debugPrint('Story refresh error: $e');
  }
}

void _handleStoryRowInit(StoryRowController controller) {
  controller._ensureMyUserPlaceholder();
  unawaited(controller._bootstrapStoryRow());
  controller._scheduleBackgroundFullLoad();
}

extension StoryRowControllerSupportPart on StoryRowController {
  void _ensureMyUserPlaceholder() {
    final myUid = _currentUid;
    if (myUid.isEmpty) return;
    if (users.any((u) => u.userID == myUid)) return;

    final nickname = userService.nickname.trim();
    final fullName = userService.fullName.trim();

    users.insert(
      0,
      StoryUserModel(
        nickname:
            nickname.isNotEmpty ? nickname : 'story.placeholder_nickname'.tr,
        avatarUrl: userService.avatarUrl,
        fullName: fullName,
        userID: myUid,
        stories: const [],
      ),
    );
  }

  String _resolveStoryNickname(Map<String, dynamic> data) {
    final nickname = (data['nickname'] ?? '').toString().trim();
    final username = (data['username'] ?? '').toString().trim();
    final usernameLower = (data['usernameLower'] ?? '').toString().trim();
    final hasSpace = hasNicknameWhitespace(nickname);
    if (nickname.isNotEmpty && !hasSpace) return nickname;
    if (username.isNotEmpty) return username;
    if (usernameLower.isNotEmpty) return usernameLower;
    return '';
  }

  String _resolveAvatar(Map<String, dynamic> data) {
    final profile = (data['profile'] is Map)
        ? Map<String, dynamic>.from(data['profile'] as Map)
        : const <String, dynamic>{};
    return resolveAvatarUrl(data, profile: profile);
  }
}
