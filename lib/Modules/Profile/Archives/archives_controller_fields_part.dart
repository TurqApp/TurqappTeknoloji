part of 'archives_controller.dart';

const Duration _archiveControllerSilentRefreshInterval = Duration(minutes: 5);

class _ArchiveControllerState {
  final ProfileRepository profileRepository = ensureProfileRepository();
  final ScrollController scrollController = ScrollController();
  final RxList<PostsModel> list = <PostsModel>[].obs;
  final RxBool isLoading = true.obs;
  final Map<String, GlobalKey> agendaKeys = {};
  final RxInt currentVisibleIndex = RxInt(-1);
  final RxInt centeredIndex = 0.obs;
  int? lastCenteredIndex;
  String? pendingCenteredDocId;
  final Map<int, double> visibleFractions = <int, double>{};
  final Map<int, DateTime> visibleUpdatedAt = <int, DateTime>{};
  Timer? visibilityDebounce;
  Timer? scrollSettleDebounce;
  DateTime? scrollStartedAt;
  double scrollStartOffset = 0.0;
  double lastObservedOffset = 0.0;
  int scrollDirection = 0;
  StreamSubscription<User?>? authSub;
  String? currentUserId;
}

extension ArchiveControllerFieldsPart on ArchiveController {
  ProfileRepository get _profileRepository => _state.profileRepository;
  ScrollController get scrollController => _state.scrollController;
  RxList<PostsModel> get list => _state.list;
  RxBool get isLoading => _state.isLoading;
  Map<String, GlobalKey> get _agendaKeys => _state.agendaKeys;
  RxInt get currentVisibleIndex => _state.currentVisibleIndex;
  RxInt get centeredIndex => _state.centeredIndex;
  int? get lastCenteredIndex => _state.lastCenteredIndex;
  set lastCenteredIndex(int? value) => _state.lastCenteredIndex = value;
  String? get _pendingCenteredDocId => _state.pendingCenteredDocId;
  set _pendingCenteredDocId(String? value) =>
      _state.pendingCenteredDocId = value;
  Map<int, double> get _visibleFractions => _state.visibleFractions;
  Map<int, DateTime> get _visibleUpdatedAt => _state.visibleUpdatedAt;
  Timer? get _visibilityDebounce => _state.visibilityDebounce;
  set _visibilityDebounce(Timer? value) => _state.visibilityDebounce = value;
  Timer? get _scrollSettleDebounce => _state.scrollSettleDebounce;
  set _scrollSettleDebounce(Timer? value) =>
      _state.scrollSettleDebounce = value;
  DateTime? get _scrollStartedAt => _state.scrollStartedAt;
  set _scrollStartedAt(DateTime? value) => _state.scrollStartedAt = value;
  double get _scrollStartOffset => _state.scrollStartOffset;
  set _scrollStartOffset(double value) => _state.scrollStartOffset = value;
  double get _lastObservedOffset => _state.lastObservedOffset;
  set _lastObservedOffset(double value) => _state.lastObservedOffset = value;
  int get _scrollDirection => _state.scrollDirection;
  set _scrollDirection(int value) => _state.scrollDirection = value;
  StreamSubscription<User?>? get _authSub => _state.authSub;
  set _authSub(StreamSubscription<User?>? value) => _state.authSub = value;
  String? get _currentUserId => _state.currentUserId;
  set _currentUserId(String? value) => _state.currentUserId = value;
  String get _resolvedCurrentUid => CurrentUserService.instance.effectiveUserId;
}
