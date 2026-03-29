part of 'account_center_service.dart';

extension AccountCenterServiceStoragePart on AccountCenterService {
  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  int _nextSortOrderForPinned(bool isPinned, {String? excludingUid}) {
    final scoped = accounts.where(
      (item) => item.isPinned == isPinned && item.uid != excludingUid,
    );
    if (scoped.isEmpty) return 1;
    return scoped
            .map((item) => item.sortOrder)
            .reduce((value, element) => value > element ? value : element) +
        1;
  }

  Future<void> init() async {
    if (_initialized) return;
    final inFlight = _initFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }
    final future = _performInit();
    _initFuture = future;
    try {
      await future;
      _initialized = true;
    } finally {
      if (identical(_initFuture, future)) {
        _initFuture = null;
      }
    }
  }

  Future<void> _performInit() async {
    await _ensurePrefs();
    await AccountSessionVault.instance.removeStoredPasswords();
    final raw = _prefs?.getString(_accountCenterAccountsStorageKey) ?? '';
    List<StoredAccount> decodedAccounts;
    try {
      decodedAccounts = StoredAccount.decodeList(raw).toList(growable: true);
    } catch (_) {
      decodedAccounts = <StoredAccount>[];
      if (raw.trim().isNotEmpty) {
        await _prefs?.remove(_accountCenterAccountsStorageKey);
      }
    }
    final restored = _dedupeAccounts(
      decodedAccounts,
    )..sort(_compareAccounts);
    final shouldPersistAccounts = restored.length != decodedAccounts.length;
    if (_shouldLogDebug) {
      debugPrint(
        '[AccountCenter] init rawLength=${raw.length} restored=${restored.map((e) => e.uid).toList()}',
      );
    }
    accounts.assignAll(restored);
    var shouldPersistPointers = false;
    activeUid.value =
        (_prefs?.getString(_accountCenterActiveUidStorageKey) ?? '').trim();
    if (activeUid.value.isNotEmpty && accountByUid(activeUid.value) == null) {
      activeUid.value = '';
      shouldPersistPointers = true;
    }
    lastUsedUid.value =
        (_prefs?.getString(_accountCenterLastUsedUidStorageKey) ?? '').trim();
    if (lastUsedUid.value.isNotEmpty &&
        accountByUid(lastUsedUid.value) == null) {
      lastUsedUid.value = '';
      shouldPersistPointers = true;
    }
    await _rehydrateMissingEmails();
    await reconcileWithAuthSession();
    if (shouldPersistAccounts || shouldPersistPointers) {
      await _persist();
    }
  }

  Future<void> _rehydrateMissingEmails() async {
    final current = accounts.toList(growable: true);
    var changed = false;
    for (var i = 0; i < current.length; i++) {
      final account = current[i];
      if (account.email.trim().isNotEmpty) continue;

      var resolvedEmail = '';
      final storedCredential =
          await AccountSessionVault.instance.read(account.uid);
      if (storedCredential != null) {
        resolvedEmail = normalizeEmailAddress(storedCredential.email);
      }

      if (resolvedEmail.isEmpty) {
        final raw = await UserRepository.ensure().getUserRaw(
          account.uid,
          preferCache: true,
        );
        resolvedEmail = normalizeEmailAddress((raw?['email'] ?? '').toString());
      }

      if (resolvedEmail.isEmpty && isCurrentUserId(account.uid)) {
        resolvedEmail =
            normalizeEmailAddress(CurrentUserService.instance.effectiveEmail);
      }

      if (resolvedEmail.isEmpty) continue;
      current[i] = account.copyWith(email: resolvedEmail);
      changed = true;
    }

    final deduped = _dedupeAccounts(current)..sort(_compareAccounts);
    final structurallyChanged = changed || deduped.length != accounts.length;
    if (!structurallyChanged) return;
    accounts.assignAll(deduped);
    await _persist();
  }

  List<StoredAccount> _dedupeAccounts(List<StoredAccount> source) {
    final byIdentity = <String, StoredAccount>{};
    for (final account in source) {
      final email = normalizeEmailAddress(account.email);
      final key =
          email.isNotEmpty ? 'email:$email' : 'uid:${account.uid.trim()}';
      final existing = byIdentity[key];
      if (existing == null) {
        byIdentity[key] = account;
        continue;
      }
      final preferred = _preferAccount(existing, account);
      byIdentity[key] = preferred;
    }
    return byIdentity.values.toList(growable: true);
  }

  StoredAccount _preferAccount(StoredAccount a, StoredAccount b) {
    if (a.lastSuccessfulSignInAt != b.lastSuccessfulSignInAt) {
      return a.lastSuccessfulSignInAt >= b.lastSuccessfulSignInAt ? a : b;
    }
    if (a.lastUsedAt != b.lastUsedAt) {
      return a.lastUsedAt >= b.lastUsedAt ? a : b;
    }
    if (a.isSessionValid != b.isSessionValid) {
      return a.isSessionValid ? a : b;
    }
    return a.sortOrder <= b.sortOrder ? a : b;
  }

  Future<void> reconcileWithAuthSession() async {
    await _ensurePrefs();
    final authUid = CurrentUserService.instance.effectiveUserId.trim();
    if (authUid.isEmpty) {
      if (activeUid.value.isNotEmpty) {
        activeUid.value = '';
        await _prefs?.remove(_accountCenterActiveUidStorageKey);
      }
      if (lastUsedUid.value.isNotEmpty &&
          accountByUid(lastUsedUid.value) == null) {
        lastUsedUid.value = accounts.isNotEmpty ? accounts.first.uid : '';
      }
      if (lastUsedUid.value.isEmpty) {
        await _prefs?.remove(_accountCenterLastUsedUidStorageKey);
      } else {
        await _prefs?.setString(
          _accountCenterLastUsedUidStorageKey,
          lastUsedUid.value,
        );
      }
      return;
    }
    if (activeUid.value == authUid) return;
    activeUid.value = authUid;
    await _prefs?.setString(_accountCenterActiveUidStorageKey, authUid);
    if (lastUsedUid.value.isEmpty || accountByUid(lastUsedUid.value) == null) {
      lastUsedUid.value = authUid;
      await _prefs?.setString(_accountCenterLastUsedUidStorageKey, authUid);
    }
  }

  Future<void> _persist() async {
    await _prefs?.setString(
      _accountCenterAccountsStorageKey,
      StoredAccount.encodeList(accounts),
    );
    if (activeUid.value.isNotEmpty) {
      await _prefs?.setString(
        _accountCenterActiveUidStorageKey,
        activeUid.value,
      );
    } else {
      await _prefs?.remove(_accountCenterActiveUidStorageKey);
    }
    if (lastUsedUid.value.isNotEmpty) {
      await _prefs?.setString(
        _accountCenterLastUsedUidStorageKey,
        lastUsedUid.value,
      );
    } else {
      await _prefs?.remove(_accountCenterLastUsedUidStorageKey);
    }
    if (_shouldLogDebug) {
      final stored = _prefs?.getString(_accountCenterAccountsStorageKey) ?? '';
      debugPrint(
        '[AccountCenter] persist storedLength=${stored.length} '
        'accounts=${accounts.map((e) => e.uid).toList()}',
      );
    }
  }
}
