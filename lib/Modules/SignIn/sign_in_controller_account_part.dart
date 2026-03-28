part of 'sign_in_controller.dart';

extension SignInControllerAccountPart on SignInController {
  Future<void> _trackCurrentAccountForDevice() async {
    final userService = CurrentUserService.instance;
    final firebaseUser = userService.currentAuthUser;
    final currentUser = userService.currentUser;
    if (firebaseUser == null) return;
    if (kDebugMode) {
      debugPrint(
        '[AccountCenterTrack] start uid=${firebaseUser.uid} currentUserReady=${currentUser != null}',
      );
    }
    final service = ensureAccountCenterService();
    await service.init();
    if (currentUser != null) {
      if (kDebugMode) {
        debugPrint(
          '[AccountCenterTrack] source=currentUser nickname=${currentUser.nickname} uid=${currentUser.userID}',
        );
      }
      await service.addCurrentAccount(
        currentUser: currentUser,
        firebaseUser: firebaseUser,
        markSuccessfulSignIn: true,
      );
    } else {
      final summary = await _userRepository.getUser(
        firebaseUser.uid,
        preferCache: true,
      );
      if (summary != null) {
        if (kDebugMode) {
          debugPrint(
            '[AccountCenterTrack] source=userSummary username=${summary.username} uid=${summary.userID}',
          );
        }
        await service.addOrUpdateAccount(
          StoredAccount.fromUserSummary(
            user: summary,
            firebaseUser: firebaseUser,
          ),
          markSuccessfulSignIn: true,
        );
      } else {
        if (kDebugMode) {
          debugPrint(
            '[AccountCenterTrack] source=firebaseUser email=${firebaseUser.email} uid=${firebaseUser.uid}',
          );
        }
        await service.addOrUpdateAccount(
          StoredAccount.fromFirebaseUser(firebaseUser),
          markSuccessfulSignIn: true,
        );
      }
    }
    if (kDebugMode) {
      debugPrint(
        '[AccountCenterTrack] done uid=${firebaseUser.uid} accounts=${service.accounts.map((e) => e.uid).toList()}',
      );
    }
  }

  String _resolvedSignInEmail() {
    final raw = emailcontroller.text.trim();
    if (raw.contains('@')) return normalizeEmailAddress(raw);
    return normalizeEmailAddress(signInEmail.value);
  }

  Future<void> _persistStoredSessionHint({
    String? email,
  }) async {
    final userService = CurrentUserService.instance;
    final authUser = userService.currentAuthUser;
    final resolvedEmail =
        normalizeEmailAddress(email ?? userService.effectiveEmail);
    if (authUser == null || resolvedEmail.isEmpty) {
      return;
    }
    await AccountSessionVault.instance.saveEmailHint(
      uid: authUser.uid,
      email: resolvedEmail,
      password: '',
    );
  }

  Future<String> preferredIdentifierForStoredAccount(
      StoredAccount account) async {
    final emailFromAccount = normalizeEmailAddress(account.email);
    if (emailFromAccount.isNotEmpty) return emailFromAccount;
    if (account.hasPasswordProvider) {
      final credential = await AccountSessionVault.instance.read(account.uid);
      final email = normalizeEmailAddress(credential?.email);
      if (email.isNotEmpty) return email;
    }
    return account.username;
  }

  void prepareSignInPrefill(String identifier) {
    final normalized = identifier.trim();
    if (normalized.isEmpty) {
      emailcontroller.clear();
      passwordcontroller.clear();
      email.value = '';
      password.value = '';
      signInEmail.value = '';
      selection.value = 0;
      return;
    }
    emailcontroller.text = normalized;
    email.value = normalized;
    signInEmail.value = normalized.contains('@') ? normalized : '';
    passwordcontroller.clear();
    password.value = '';
    selection.value = 1;
  }

  void prepareStoredAccountContext(String uid) {
    final normalized = uid.trim();
    if (normalized.isEmpty) {
      selectedStoredAccount.value = null;
      return;
    }
    selectedStoredAccount.value =
        ensureAccountCenterService().accountByUid(normalized);
  }

  Future<void> continueWithStoredAccount(StoredAccount account) async {
    prepareSignInPrefill(await preferredIdentifierForStoredAccount(account));
    selectedStoredAccount.value = account;
  }

  void clearStoredAccountContext() {
    selectedStoredAccount.value = null;
  }

  void maybeClearStoredAccountContextForIdentifier(String identifier) {
    final selected = selectedStoredAccount.value;
    if (selected == null) return;
    final normalized = normalizeNicknameInput(identifier);
    final selectedUsername = normalizeNicknameInput(selected.username);
    if (normalized.isEmpty || normalized != selectedUsername) {
      selectedStoredAccount.value = null;
    }
  }
}
