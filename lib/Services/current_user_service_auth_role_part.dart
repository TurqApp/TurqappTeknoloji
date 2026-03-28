part of 'current_user_service.dart';

class CurrentUserAuthRole {
  CurrentUserAuthRole(
    this.service, {
    User? Function()? currentAuthUserProvider,
    Stream<User?> Function()? authStateChangesProvider,
  })  : _currentAuthUserProvider =
            currentAuthUserProvider ?? (() => FirebaseAuth.instance.currentUser),
        _authStateChangesProvider =
            authStateChangesProvider ?? (() => FirebaseAuth.instance.authStateChanges());

  final CurrentUserService service;
  final User? Function() _currentAuthUserProvider;
  final Stream<User?> Function() _authStateChangesProvider;

  String effectiveUserId() {
    final cachedUid = (service._currentUser?.userID ?? '').trim();
    if (cachedUid.isNotEmpty) return cachedUid;
    return authUserId();
  }

  User? currentAuthUser() => _currentAuthUserProvider();

  bool hasAuthUser() => currentAuthUser() != null;

  String authUserId() => currentAuthUser()?.uid.trim() ?? '';

  String authEmail() => currentAuthUser()?.email?.trim() ?? '';

  String authDisplayName() => currentAuthUser()?.displayName?.trim() ?? '';

  String effectiveEmail() {
    final cached = service.email.trim();
    if (cached.isNotEmpty) return cached;
    return authEmail();
  }

  String effectivePhoneNumber() {
    final cached = service.phoneNumber.trim();
    if (cached.isNotEmpty) return cached;
    return currentAuthUser()?.phoneNumber?.trim() ?? '';
  }

  String effectiveDisplayName() {
    final cachedFullName = service.fullName.trim();
    if (cachedFullName.isNotEmpty) return cachedFullName;
    final cachedNickname = service.nickname.trim();
    if (cachedNickname.isNotEmpty) return cachedNickname;
    return authDisplayName();
  }

  Stream<User?> authStateChanges() => _authStateChangesProvider();

  Future<User?> resolveAuthUser({
    bool waitForAuthState = false,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final existing = currentAuthUser();
    if (existing != null) return existing;
    if (!waitForAuthState) return null;
    try {
      return await authStateChanges()
          .firstWhere((candidate) => candidate != null)
          .timeout(timeout);
    } catch (_) {
      return currentAuthUser();
    }
  }

  Future<User?> reloadCurrentAuthUser() async {
    final user = currentAuthUser();
    if (user == null) return null;
    await user.reload();
    return currentAuthUser();
  }

  Future<String?> ensureAuthReady({
    bool waitForAuthState = false,
    bool forceTokenRefresh = false,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final user = await resolveAuthUser(
      waitForAuthState: waitForAuthState,
      timeout: timeout,
    );
    if (user == null) return null;
    if (forceTokenRefresh) {
      try {
        await user.getIdToken(true);
      } catch (_) {
        // Best effort refresh only.
      }
    }
    final uid = user.uid.trim();
    return uid.isEmpty ? null : uid;
  }

  Future<void> refreshAuthTokenIfNeeded({
    bool waitForAuthState = true,
  }) async {
    try {
      await ensureAuthReady(
        waitForAuthState: waitForAuthState,
        forceTokenRefresh: true,
      );
    } catch (_) {
      // Best effort only.
    }
  }

  Future<void> signOutAuth() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> deleteAuthUserIfPresent() async {
    final user = currentAuthUser();
    if (user == null) return;
    try {
      await user.delete();
    } catch (_) {
      rethrow;
    }
  }
}
