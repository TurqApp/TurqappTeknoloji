part of 'account_center_service.dart';

class _AccountCenterServiceState {
  final accounts = <StoredAccount>[].obs;
  final activeUid = ''.obs;
  final lastUsedUid = ''.obs;
  SharedPreferences? prefs;
  bool initScheduled = false;
  bool initialized = false;
  Future<void>? initFuture;
  final userSummaryResolver = UserSummaryResolver.ensure();
}

extension AccountCenterServiceFieldsPart on AccountCenterService {
  RxList<StoredAccount> get accounts => _state.accounts;
  RxString get activeUid => _state.activeUid;
  RxString get lastUsedUid => _state.lastUsedUid;
  SharedPreferences? get _prefs => _state.prefs;
  set _prefs(SharedPreferences? value) => _state.prefs = value;
  bool get _initScheduled => _state.initScheduled;
  set _initScheduled(bool value) => _state.initScheduled = value;
  bool get _initialized => _state.initialized;
  set _initialized(bool value) => _state.initialized = value;
  Future<void>? get _initFuture => _state.initFuture;
  set _initFuture(Future<void>? value) => _state.initFuture = value;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
}
