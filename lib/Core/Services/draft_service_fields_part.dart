part of 'draft_service_library.dart';

class _DraftServiceState {
  final RxList<PostDraft> drafts = <PostDraft>[].obs;
  final RxBool autoSaveEnabled = true.obs;
  final RxInt autoSaveInterval = 30.obs;
  StreamSubscription<User?>? authSub;
}

extension DraftServiceFieldsPart on DraftService {
  RxList<PostDraft> get _drafts => _state.drafts;
  RxBool get _autoSaveEnabled => _state.autoSaveEnabled;
  RxInt get _autoSaveInterval => _state.autoSaveInterval;
  StreamSubscription<User?>? get _authSub => _state.authSub;
  set _authSub(StreamSubscription<User?>? value) => _state.authSub = value;

  String get _activeDraftsKey => userScopedKey(DraftService._draftsKeyPrefix);
}
