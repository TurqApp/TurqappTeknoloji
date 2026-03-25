part of 'current_user_service.dart';

extension CurrentUserServiceAuthPart on CurrentUserService {
  String _performEffectiveUserId() {
    final cachedUid = (_currentUser?.userID ?? '').trim();
    if (cachedUid.isNotEmpty) return cachedUid;
    return authUserId;
  }

  User? _performCurrentAuthUser() => FirebaseAuth.instance.currentUser;

  bool _performHasAuthUser() => currentAuthUser != null;

  String _performAuthUserId() => currentAuthUser?.uid.trim() ?? '';

  String _performAuthEmail() => currentAuthUser?.email?.trim() ?? '';

  String _performAuthDisplayName() =>
      currentAuthUser?.displayName?.trim() ?? '';

  String _performEffectiveEmail() {
    final cached = email.trim();
    if (cached.isNotEmpty) return cached;
    return authEmail;
  }

  String _performEffectivePhoneNumber() {
    final cached = phoneNumber.trim();
    if (cached.isNotEmpty) return cached;
    return currentAuthUser?.phoneNumber?.trim() ?? '';
  }

  String _performEffectiveDisplayName() {
    final cachedFullName = fullName.trim();
    if (cachedFullName.isNotEmpty) return cachedFullName;
    final cachedNickname = nickname.trim();
    if (cachedNickname.isNotEmpty) return cachedNickname;
    return authDisplayName;
  }

  Stream<User?> _performAuthStateChanges() =>
      FirebaseAuth.instance.authStateChanges();

  Future<User?> _performResolveAuthUser({
    bool waitForAuthState = false,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final existing = currentAuthUser;
    if (existing != null) return existing;
    if (!waitForAuthState) return null;
    try {
      return await authStateChanges()
          .firstWhere((candidate) => candidate != null)
          .timeout(timeout);
    } catch (_) {
      return currentAuthUser;
    }
  }

  Future<User?> _performReloadCurrentAuthUser() async {
    final user = currentAuthUser;
    if (user == null) return null;
    await user.reload();
    return currentAuthUser;
  }

  Future<String?> _performEnsureAuthReady({
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

  Future<void> _performRefreshAuthTokenIfNeeded({
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

  Future<void> _performSignOutAuth() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _performDeleteAuthUserIfPresent() async {
    final user = currentAuthUser;
    if (user == null) return;
    try {
      await user.delete();
    } catch (_) {
      rethrow;
    }
  }
}
