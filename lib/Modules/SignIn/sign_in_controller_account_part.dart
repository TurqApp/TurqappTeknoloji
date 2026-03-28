part of 'sign_in_controller.dart';

extension SignInControllerAccountPart on SignInController {
  Future<void> _trackCurrentAccountForDevice() async {
    await _signInApplicationService.trackCurrentAccountForDevice();
  }

  String _resolvedSignInEmail() {
    final raw = emailcontroller.text.trim();
    if (raw.contains('@')) return normalizeEmailAddress(raw);
    return normalizeEmailAddress(signInEmail.value);
  }

  Future<void> _persistStoredSessionHint({
    String? email,
  }) async {
    await _signInApplicationService.persistStoredSessionHint(
      email: email,
    );
  }

  Future<String> preferredIdentifierForStoredAccount(
      StoredAccount account) async {
    return _signInApplicationService.preferredIdentifierForStoredAccount(
      account,
    );
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

  void _openStoredAccountSignInForm(String identifier) {
    final normalized = identifier.trim();
    if (normalized.isNotEmpty) {
      prepareSignInPrefill(normalized);
      return;
    }
    emailcontroller.clear();
    passwordcontroller.clear();
    email.value = '';
    password.value = '';
    signInEmail.value = '';
    selection.value = 1;
  }

  Future<void> prepareStoredAccountContext(
    String uid, {
    String initialIdentifier = '',
  }) async {
    final normalized = uid.trim();
    if (normalized.isEmpty) {
      selectedStoredAccount.value = null;
      return;
    }
    final normalizedInitialIdentifier = initialIdentifier.trim();
    final accountCenterService = ensureAccountCenterService();
    await accountCenterService.init();
    final account = accountCenterService.accountByUid(normalized);
    if (account == null) {
      selectedStoredAccount.value = null;
      if (normalizedInitialIdentifier.isEmpty) {
        _openStoredAccountSignInForm('');
      }
      return;
    }
    final context =
        await _signInApplicationService.continueWithStoredAccount(account);
    selectedStoredAccount.value = context.account;
    _openStoredAccountSignInForm(
      normalizedInitialIdentifier.isNotEmpty
          ? normalizedInitialIdentifier
          : context.identifier,
    );
  }

  Future<void> continueWithStoredAccount(StoredAccount account) async {
    final context =
        await _signInApplicationService.continueWithStoredAccount(account);
    selectedStoredAccount.value = context.account;
    _openStoredAccountSignInForm(context.identifier);
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
