import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import '../../../Core/Services/turq_image_cache_manager.dart';
import '../../../Core/Services/ContentPolicy/content_policy.dart';
import '../../../Core/Services/user_profile_cache_service.dart';
import '../../../Core/Utils/avatar_url.dart';
import '../../../Core/Utils/nickname_utils.dart';
import '../../../Services/current_user_service.dart';
import '../../../Services/user_analytics_service.dart';
import '../StoryMaker/story_model.dart';
import 'story_user_model.dart';

part 'story_row_controller_cache_part.dart';
part 'story_row_controller_load_part.dart';

class StoryRowController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  static StoryRowController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(StoryRowController());
  }

  static StoryRowController? maybeFind() {
    final isRegistered = Get.isRegistered<StoryRowController>();
    if (!isRegistered) return null;
    return Get.find<StoryRowController>();
  }

  RxList<StoryUserModel> users = <StoryUserModel>[].obs;
  final userService = CurrentUserService.instance;
  UserProfileCacheService get _userCache => UserProfileCacheService.ensure();

  final int initialLimit = 30;
  final int fullLimit = 100;
  bool _backgroundScheduled = false;
  final RxBool isLoading = false.obs;
  static const Duration _expireCleanupInterval = Duration(minutes: 15);
  DateTime? _lastExpireCleanupAt;
  final StoryRepository _storyRepository = StoryRepository.ensure();

  String get _currentUid => userService.effectiveUserId;

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

  // Auto refresh için static method
  static Future<void> refreshStoriesGlobally() async {
    try {
      final controller = maybeFind();
      if (controller == null) return;
      await controller.loadStories();
    } catch (e) {
      debugPrint("Story refresh error: $e");
    }
  }

  @override
  void onInit() {
    super.onInit();
    _ensureMyUserPlaceholder();
    unawaited(_bootstrapStoryRow());
    // Main.dart'ta zaten hikayeler yüklendiği için burada sadece listener'ları bağla
    // Arka planda tam listeyi genişlet (düşük öncelik)
    _scheduleBackgroundFullLoad();
  }
}
