part of 'story_row_controller.dart';

const Duration _storyRowSilentRefreshInterval = Duration(minutes: 5);
const Duration _storyRowExpireCleanupInterval = Duration(minutes: 15);
const int _storyRowIncrementLimit = 5;
const int _storyRowLoadMoreThreshold = 5;

class _StoryRowControllerState {
  final users = <StoryUserModel>[].obs;
  final StoryRowApplicationService storyRowApplicationService =
      StoryRowApplicationService();
  final CurrentUserService userService = CurrentUserService.instance;
  final UserProfileCacheService userCache = ensureUserProfileCacheService();
  final int initialLimit = ReadBudgetRegistry.storyInitialLimit;
  final int fullLimit = ReadBudgetRegistry.storyFullLimit;
  int currentLimit = ReadBudgetRegistry.storyInitialLimit;
  bool isLoadingMore = false;
  final RxBool isLoading = false.obs;
  DateTime? lastExpireCleanupAt;
  final StoryRepository storyRepository = StoryRepository.ensure();
}

extension StoryRowControllerFieldsPart on StoryRowController {
  bool get _shouldLogDebug => kDebugMode && !IntegrationTestMode.enabled;
  RxList<StoryUserModel> get users => _state.users;
  StoryRowApplicationService get _storyRowApplicationService =>
      _state.storyRowApplicationService;
  CurrentUserService get userService => _state.userService;
  UserProfileCacheService get _userCache => _state.userCache;
  int get initialLimit => _state.initialLimit;
  int get fullLimit => _state.fullLimit;
  int get _currentLimit => _state.currentLimit;
  set _currentLimit(int value) => _state.currentLimit = value;
  bool get _isLoadingMore => _state.isLoadingMore;
  set _isLoadingMore(bool value) => _state.isLoadingMore = value;
  RxBool get isLoading => _state.isLoading;
  DateTime? get _lastExpireCleanupAt => _state.lastExpireCleanupAt;
  set _lastExpireCleanupAt(DateTime? value) =>
      _state.lastExpireCleanupAt = value;
  StoryRepository get _storyRepository => _state.storyRepository;
  String get _currentUid => userService.effectiveUserId;
}
