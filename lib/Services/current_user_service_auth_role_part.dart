part of 'current_user_service.dart';

User? _safeCurrentAuthUser() {
  try {
    return FirebaseAuth.instance.currentUser;
  } catch (_) {
    return null;
  }
}

Stream<User?> _safeAuthStateChanges() {
  try {
    return FirebaseAuth.instance.authStateChanges();
  } catch (_) {
    return const Stream<User?>.empty();
  }
}

Future<void> _safeSignOutAuth() async {
  try {
    await FirebaseAuth.instance.signOut();
  } catch (_) {}
}

class CurrentUserAuthRole {
  CurrentUserAuthRole(
    this.service, {
    User? Function()? currentAuthUserProvider,
    Stream<User?> Function()? authStateChangesProvider,
    StartupSessionFailureReporter? failureReporter,
  })  : _currentAuthUserProvider =
            currentAuthUserProvider ?? _safeCurrentAuthUser,
        _authStateChangesProvider =
            authStateChangesProvider ?? _safeAuthStateChanges,
        _failureReporter =
            failureReporter ?? StartupSessionFailureReporter.defaultReporter;

  final CurrentUserService service;
  final User? Function() _currentAuthUserProvider;
  final Stream<User?> Function() _authStateChangesProvider;
  final StartupSessionFailureReporter _failureReporter;

  String effectiveUserId() {
    final cachedUid = (service._currentUser?.userID ?? '').trim();
    if (cachedUid.isNotEmpty) return cachedUid;
    return authUserId();
  }

  User? currentAuthUser() {
    try {
      return _currentAuthUserProvider();
    } catch (_) {
      return null;
    }
  }

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

  Stream<User?> authStateChanges() {
    try {
      return _authStateChangesProvider();
    } catch (_) {
      return const Stream<User?>.empty();
    }
  }

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
    } catch (error, stackTrace) {
      _failureReporter.record(
        kind: StartupSessionFailureKind.authStateRestore,
        operation: 'CurrentUserAuthRole.resolveAuthUser',
        error: error,
        stackTrace: stackTrace,
      );
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
      } catch (error, stackTrace) {
        _failureReporter.record(
          kind: StartupSessionFailureKind.authTokenRefresh,
          operation: 'CurrentUserAuthRole.ensureAuthReady.forceTokenRefresh',
          error: error,
          stackTrace: stackTrace,
        );
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
    } catch (error, stackTrace) {
      _failureReporter.record(
        kind: StartupSessionFailureKind.authTokenRefresh,
        operation: 'CurrentUserAuthRole.refreshAuthTokenIfNeeded',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> signOutAuth() async {
    await _safeSignOutAuth();
  }

  Future<void> deleteAuthUserIfPresent() async {
    final user = currentAuthUser();
    if (user == null) return;
    try {
      await user.delete();
    } catch (error, stackTrace) {
      _failureReporter.record(
        kind: StartupSessionFailureKind.authStateRestore,
        operation: 'CurrentUserAuthRole.deleteAuthUserIfPresent',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
