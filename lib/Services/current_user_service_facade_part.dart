part of 'current_user_service.dart';

extension CurrentUserServiceFacadePart on CurrentUserService {
  String get effectiveUserId => _performEffectiveUserId();

  CurrentUserModel? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  String get userId {
    final cached = (_currentUser?.userID ?? '').trim();
    if (cached.isNotEmpty) return cached;
    return effectiveUserId;
  }

  User? get currentAuthUser => _performCurrentAuthUser();

  bool get hasAuthUser => _performHasAuthUser();

  String get authUserId => _performAuthUserId();

  String get authEmail => _performAuthEmail();

  String get authDisplayName => _performAuthDisplayName();

  String get effectiveEmail => _performEffectiveEmail();

  String get effectivePhoneNumber => _performEffectivePhoneNumber();

  String get effectiveDisplayName => _performEffectiveDisplayName();

  Stream<User?> authStateChanges() => _performAuthStateChanges();

  Future<User?> resolveAuthUser({
    bool waitForAuthState = false,
    Duration timeout = const Duration(seconds: 3),
  }) =>
      _performResolveAuthUser(
        waitForAuthState: waitForAuthState,
        timeout: timeout,
      );

  Future<User?> reloadCurrentAuthUser() => _performReloadCurrentAuthUser();

  Future<String?> ensureAuthReady({
    bool waitForAuthState = false,
    bool forceTokenRefresh = false,
    Duration timeout = const Duration(seconds: 3),
  }) =>
      _performEnsureAuthReady(
        waitForAuthState: waitForAuthState,
        forceTokenRefresh: forceTokenRefresh,
        timeout: timeout,
      );

  Future<void> refreshAuthTokenIfNeeded({
    bool waitForAuthState = true,
  }) =>
      _performRefreshAuthTokenIfNeeded(
        waitForAuthState: waitForAuthState,
      );

  Future<void> signOutAuth() => _performSignOutAuth();

  Future<void> deleteAuthUserIfPresent() => _performDeleteAuthUserIfPresent();

  String get nickname => _currentUser?.nickname ?? '';

  String get firstName => _currentUser?.firstName ?? '';

  String get lastName => _currentUser?.lastName ?? '';

  String get rozet => _currentUser?.rozet ?? '';

  String get email => _currentUser?.email ?? '';

  String get phoneNumber => _currentUser?.phoneNumber ?? '';

  String get bio => _currentUser?.bio ?? '';

  String get meslekKategori => _currentUser?.meslekKategori ?? '';

  String get adres => _currentUser?.adres ?? '';

  int get counterOfPosts => _currentUser?.counterOfPosts ?? 0;

  int get counterOfLikes => _currentUser?.counterOfLikes ?? 0;

  String get avatarUrl {
    final raw = (_currentUser?.avatarUrl ?? '').trim();
    return isDefaultAvatarUrl(raw) ? '' : raw;
  }

  String get fullName => _currentUser?.fullName ?? '';

  int get effectiveViewSelection => viewSelectionRx.value;

  Future<bool> initialize() => _performInitialize();

  Future<void> forceRefresh() => _performForceRefresh();

  Future<void> _startFirebaseSync() => _performStartFirebaseSync();

  Future<void> _adoptFreshSessionKeyIfNeeded() =>
      _performAdoptFreshSessionKeyIfNeeded();

  void _startExclusiveSessionHeartbeat(String uid) =>
      _performStartExclusiveSessionHeartbeat(uid);

  Future<void> _validateExclusiveSessionFromServer(String uid) =>
      _performValidateExclusiveSessionFromServer(uid);

  Future<Map<String, dynamic>> _buildMergedUserData({
    required String uid,
    required Map<String, dynamic> rootData,
  }) =>
      _performBuildMergedUserData(
        uid: uid,
        rootData: rootData,
      );

  Future<void> _stopFirebaseSync() => _performStopFirebaseSync();

  Future<void> _updateUser(CurrentUserModel user) async {
    await _performUpdateUser(user);
  }

  Future<bool> _handlePermanentBanIfNeeded(CurrentUserModel user) async {
    return _performHandlePermanentBanIfNeeded(user);
  }

  Future<bool> _handleExclusiveSessionIfNeeded(
    String uid,
    Map<String, dynamic> data,
  ) async {
    return _performHandleExclusiveSessionIfNeeded(uid, data);
  }

  bool _publishResolvedUser(CurrentUserModel user) {
    return _performPublishResolvedUser(user);
  }

  Future<void> _warmAvatar(CurrentUserModel? user) async {
    await _performWarmAvatar(user);
  }

  Future<void> _signOutToSignIn({
    String initialIdentifier = '',
  }) async {
    await _performSignOutToSignIn(initialIdentifier: initialIdentifier);
  }

  bool isUserBlocked(String userId) {
    return _currentUser?.blockedUsers.contains(userId) ?? false;
  }

  bool get isEmailVerified => emailVerifiedRx.value;

  Future<void> logout() async {
    await _performLogout();
  }
}
