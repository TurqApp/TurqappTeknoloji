import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
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
part 'story_row_controller_support_part.dart';

class StoryRowController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  bool get _shouldLogDebug => kDebugMode && !IntegrationTestMode.enabled;

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

  static Future<void> refreshStoriesGlobally() => _refreshStoryRowGlobally();

  @override
  void onInit() {
    super.onInit();
    _handleStoryRowInit(this);
  }
}
