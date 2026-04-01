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
  StreamSubscription<User?>? get _authSub => _state.authSub;
  set _authSub(StreamSubscription<User?>? value) => _state.authSub = value;
  String? get _currentUserId => _state.currentUserId;
  set _currentUserId(String? value) => _state.currentUserId = value;
  String get _resolvedCurrentUid => CurrentUserService.instance.effectiveUserId;
}
