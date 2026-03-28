part of 'story_row_controller.dart';

const Duration _storyRowSilentRefreshInterval = Duration(minutes: 5);
const Duration _storyRowExpireCleanupInterval = Duration(minutes: 15);

class _StoryRowControllerState {
  final users = <StoryUserModel>[].obs;
  final StoryRowApplicationService storyRowApplicationService =
      StoryRowApplicationService();
  final CurrentUserService userService = CurrentUserService.instance;
  final UserProfileCacheService userCache = ensureUserProfileCacheService();
  final int initialLimit = 30;
  final int fullLimit = 100;
  bool backgroundScheduled = false;
  Timer? backgroundFullLoadTimer;
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
  bool get _backgroundScheduled => _state.backgroundScheduled;
  set _backgroundScheduled(bool value) => _state.backgroundScheduled = value;
  Timer? get _backgroundFullLoadTimer => _state.backgroundFullLoadTimer;
  set _backgroundFullLoadTimer(Timer? value) =>
      _state.backgroundFullLoadTimer = value;
  RxBool get isLoading => _state.isLoading;
  DateTime? get _lastExpireCleanupAt => _state.lastExpireCleanupAt;
  set _lastExpireCleanupAt(DateTime? value) =>
      _state.lastExpireCleanupAt = value;
  StoryRepository get _storyRepository => _state.storyRepository;
  String get _currentUid => userService.effectiveUserId;
}
