part of 'recommended_users_repository.dart';

class RecommendedUsersRepository extends GetxService {
  static const String _prefsKeyPrefix = 'recommended_users_repository_v1';
  static const Duration _ttl = Duration(minutes: 10);
  final _state = _RecommendedUsersRepositoryState();

  @override
  void onClose() {
    _handleClose();
    super.onClose();
  }
}

class _RecommendedUsersRepositoryState {
  List<RecommendedUserModel> memory = const <RecommendedUserModel>[];
  DateTime? cachedAt;
  SharedPreferences? prefs;
  bool initialized = false;
  StreamSubscription<User?>? authSub;
}

extension RecommendedUsersRepositoryFieldsPart on RecommendedUsersRepository {
  List<RecommendedUserModel> get _memory => _state.memory;
  set _memory(List<RecommendedUserModel> value) => _state.memory = value;

  DateTime? get _cachedAt => _state.cachedAt;
  set _cachedAt(DateTime? value) => _state.cachedAt = value;

  SharedPreferences? get _prefs => _state.prefs;
  set _prefs(SharedPreferences? value) => _state.prefs = value;

  bool get _initialized => _state.initialized;
  set _initialized(bool value) => _state.initialized = value;

  StreamSubscription<User?>? get _authSub => _state.authSub;
  set _authSub(StreamSubscription<User?>? value) => _state.authSub = value;

  String get _prefsKey =>
      userScopedKey(RecommendedUsersRepository._prefsKeyPrefix);

  bool get _isFresh =>
      _cachedAt != null &&
      DateTime.now().difference(_cachedAt!) <= RecommendedUsersRepository._ttl;
}
