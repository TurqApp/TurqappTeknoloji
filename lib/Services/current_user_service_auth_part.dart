part of 'current_user_service.dart';

extension CurrentUserServiceAuthPart on CurrentUserService {
  CurrentUserAuthRole get _authRole => CurrentUserAuthRole(this);

  String _performEffectiveUserId() => _authRole.effectiveUserId();

  User? _performCurrentAuthUser() => _authRole.currentAuthUser();

  bool _performHasAuthUser() => _authRole.hasAuthUser();

  String _performAuthUserId() => _authRole.authUserId();

  String _performAuthEmail() => _authRole.authEmail();

  String _performAuthDisplayName() => _authRole.authDisplayName();

  String _performEffectiveEmail() => _authRole.effectiveEmail();

  String _performEffectivePhoneNumber() => _authRole.effectivePhoneNumber();

  String _performEffectiveDisplayName() => _authRole.effectiveDisplayName();

  Stream<User?> _performAuthStateChanges() => _authRole.authStateChanges();

  Future<User?> _performResolveAuthUser({
    bool waitForAuthState = false,
    Duration timeout = const Duration(seconds: 3),
  }) =>
      _authRole.resolveAuthUser(
        waitForAuthState: waitForAuthState,
        timeout: timeout,
      );

  Future<User?> _performReloadCurrentAuthUser() =>
      _authRole.reloadCurrentAuthUser();

  Future<String?> _performEnsureAuthReady({
    bool waitForAuthState = false,
    bool forceTokenRefresh = false,
    Duration timeout = const Duration(seconds: 3),
  }) =>
      _authRole.ensureAuthReady(
        waitForAuthState: waitForAuthState,
        forceTokenRefresh: forceTokenRefresh,
        timeout: timeout,
      );

  Future<void> _performRefreshAuthTokenIfNeeded({
    bool waitForAuthState = true,
  }) =>
      _authRole.refreshAuthTokenIfNeeded(
        waitForAuthState: waitForAuthState,
      );

  Future<void> _performSignOutAuth() => _authRole.signOutAuth();

  Future<void> _performDeleteAuthUserIfPresent() =>
      _authRole.deleteAuthUserIfPresent();
}
