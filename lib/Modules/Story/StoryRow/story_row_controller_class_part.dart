part of 'story_row_controller.dart';

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
