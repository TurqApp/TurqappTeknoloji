part of 'story_row_controller.dart';

class StoryRowController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  bool get _shouldLogDebug => kDebugMode && !IntegrationTestMode.enabled;

  RxList<StoryUserModel> users = <StoryUserModel>[].obs;
  final userService = CurrentUserService.instance;
  UserProfileCacheService get _userCache => ensureUserProfileCacheService();

  final int initialLimit = 30;
  final int fullLimit = 100;
  bool _backgroundScheduled = false;
  final RxBool isLoading = false.obs;
  static const Duration _expireCleanupInterval = Duration(minutes: 15);
  DateTime? _lastExpireCleanupAt;
  final StoryRepository _storyRepository = StoryRepository.ensure();

  String get _currentUid => userService.effectiveUserId;

  @override
  void onInit() {
    super.onInit();
    _handleStoryRowInit(this);
  }
}
