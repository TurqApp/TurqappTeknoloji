part of 'account_center_service.dart';

extension AccountCenterServiceAccountsPart on AccountCenterService {
  Future<void> addOrUpdateAccount(
    StoredAccount account, {
    bool promoteActiveUid = true,
  }) async {
    await _ensurePrefs();
    if (kDebugMode) {
      debugPrint(
        '[AccountCenter] addOrUpdate uid=${account.uid} username=${account.username} '
        'sessionValid=${account.isSessionValid} promote=$promoteActiveUid before=${accounts.length}',
      );
    }
    final current = accounts.toList(growable: true);
    final index = current.indexWhere((item) => item.uid == account.uid);
    var shouldPromoteActiveUid = promoteActiveUid;
    if (index >= 0) {
      final existing = current[index];
      current[index] = account.copyWith(
        isPinned: account.isPinned,
        sortOrder:
            account.sortOrder == 0 ? existing.sortOrder : account.sortOrder,
        lastSuccessfulSignInAt: account.lastSuccessfulSignInAt == 0
            ? existing.lastSuccessfulSignInAt
            : account.lastSuccessfulSignInAt,
      );
      shouldPromoteActiveUid = promoteActiveUid && account.isSessionValid;
    } else {
      final nextSortOrder = current.isEmpty
          ? 1
          : current.map((item) => item.sortOrder).reduce(
                  (value, element) => value > element ? value : element) +
              1;
      current.add(
        account.copyWith(
          sortOrder: account.sortOrder == 0 ? nextSortOrder : account.sortOrder,
        ),
      );
      shouldPromoteActiveUid = promoteActiveUid && account.isSessionValid;
    }
    final deduped = _dedupeAccounts(current)..sort(_compareAccounts);
    accounts.assignAll(deduped);
    if (shouldPromoteActiveUid) {
      activeUid.value = account.uid;
      lastUsedUid.value = account.uid;
    }
    await _persist();
    if (kDebugMode) {
      debugPrint(
        '[AccountCenter] addOrUpdate persisted accounts=${accounts.map((e) => e.uid).toList()} '
        'active=${activeUid.value} lastUsed=${lastUsedUid.value}',
      );
    }
  }

  Future<void> addCurrentAccount({
    required CurrentUserModel currentUser,
    required User firebaseUser,
  }) async {
    final existing = accountByUid(currentUser.userID);
    final account = StoredAccount.fromCurrentUser(
      user: currentUser,
      firebaseUser: firebaseUser,
    );
    await addOrUpdateAccount(
      account.copyWith(
        lastSuccessfulSignInAt:
            existing?.lastSuccessfulSignInAt ?? account.lastSuccessfulSignInAt,
      ),
    );
  }

  Future<void> refreshCurrentAccountMetadata() async {
    final firebaseUser = CurrentUserService.instance.currentAuthUser;
    if (firebaseUser == null) return;

    final currentUser = CurrentUserService.instance.currentUser;
    if (currentUser != null && currentUser.userID == firebaseUser.uid) {
      await addCurrentAccount(
        currentUser: currentUser,
        firebaseUser: firebaseUser,
      );
      return;
    }

    final summary = await _userSummaryResolver.resolve(
      firebaseUser.uid,
      preferCache: true,
    );
    if (summary != null) {
      await addOrUpdateAccount(
        StoredAccount.fromUserSummary(
          user: summary,
          firebaseUser: firebaseUser,
        ),
      );
      return;
    }

    await addOrUpdateAccount(
      StoredAccount.fromFirebaseUser(firebaseUser),
    );
  }

  StoredAccount? accountByUid(String uid) {
    final normalized = uid.trim();
    if (normalized.isEmpty) return null;
    for (final account in accounts) {
      if (account.uid == normalized) return account;
    }
    return null;
  }

  StoredAccount? get lastUsedAccount => accountByUid(lastUsedUid.value);

  Future<void> markSessionState({
    required String uid,
    required bool isSessionValid,
    bool? requiresReauth,
  }) async {
    await _ensurePrefs();
    final existing = accountByUid(uid);
    if (existing == null) return;
    final current = accounts.toList(growable: true);
    final index = current.indexWhere((item) => item.uid == uid);
    if (index < 0) return;
    current[index] = existing.copyWith(
      isSessionValid: isSessionValid,
      requiresReauth: requiresReauth ?? existing.requiresReauth,
      lastUsedAt: DateTime.now().millisecondsSinceEpoch,
    );
    current.sort(_compareAccounts);
    accounts.assignAll(current);
    if (!isSessionValid && activeUid.value == uid) {
      activeUid.value = '';
      await _prefs?.remove(_accountCenterActiveUidStorageKey);
    }
    await _persist();
  }

  Future<void> markSuccessfulSignIn(String uid) async {
    await _ensurePrefs();
    final existing = accountByUid(uid);
    if (existing == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await addOrUpdateAccount(
      existing.copyWith(
        isSessionValid: true,
        requiresReauth: false,
        lastUsedAt: now,
        lastSuccessfulSignInAt: now,
      ),
      promoteActiveUid: true,
    );
  }

  Future<void> setSingleDeviceSessionEnabled(bool enabled) async {
    final uid = CurrentUserService.instance.effectiveUserId.trim();
    if (uid.isEmpty) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final deviceKey =
        await DeviceSessionService.instance.getOrCreateDeviceKey();
    final patch = <String, dynamic>{
      'singleDeviceSessionEnabled': enabled,
      'activeSessionUpdatedAt': nowMs,
      'updatedDate': nowMs,
    };
    if (enabled) {
      patch['activeSessionDeviceKey'] = deviceKey;
      patch['deviceID'] = deviceKey;
    } else {
      patch['activeSessionDeviceKey'] = '';
    }
    await UserRepository.ensure().updateUserFields(uid, patch);
  }

  Future<void> registerCurrentDeviceSessionIfEnabled() async {
    final uid = CurrentUserService.instance.effectiveUserId.trim();
    if (uid.isEmpty) return;
    final raw = await UserRepository.ensure().getUserRaw(
      uid,
      preferCache: false,
      forceServer: true,
    );
    if (raw == null || raw['singleDeviceSessionEnabled'] != true) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final deviceKey =
        await DeviceSessionService.instance.getOrCreateDeviceKey();
    await UserRepository.ensure().updateUserFields(uid, <String, dynamic>{
      'activeSessionDeviceKey': deviceKey,
      'activeSessionUpdatedAt': nowMs,
      'deviceID': deviceKey,
      'updatedDate': nowMs,
    });
    DeviceSessionService.instance.clearPendingSessionClaim(uid);
  }

  Future<void> togglePinned(String uid) async {
    await _ensurePrefs();
    final existing = accountByUid(uid);
    if (existing == null) return;
    final nextPinned = !existing.isPinned;
    await addOrUpdateAccount(
      existing.copyWith(
        isPinned: nextPinned,
        sortOrder: _nextSortOrderForPinned(nextPinned, excludingUid: uid),
      ),
      promoteActiveUid: false,
    );
  }

  Future<void> moveAccount(String uid, {required bool up}) async {
    await _ensurePrefs();
    final current = accounts.toList(growable: true);
    final index = current.indexWhere((item) => item.uid == uid);
    if (index < 0) return;
    final source = current[index];
    final siblings = current
        .where((item) => item.isPinned == source.isPinned)
        .toList(growable: false);
    final siblingIndex = siblings.indexWhere((item) => item.uid == uid);
    if (siblingIndex < 0) return;
    final siblingTargetIndex = up ? siblingIndex - 1 : siblingIndex + 1;
    if (siblingTargetIndex < 0 || siblingTargetIndex >= siblings.length) {
      return;
    }
    final siblingTarget = siblings[siblingTargetIndex];
    final targetIndex =
        current.indexWhere((item) => item.uid == siblingTarget.uid);
    if (targetIndex < 0) return;
    final target = current[targetIndex];
    current[index] = source.copyWith(sortOrder: target.sortOrder);
    current[targetIndex] = target.copyWith(sortOrder: source.sortOrder);
    current.sort(_compareAccounts);
    accounts.assignAll(current);
    await _persist();
  }

  Future<void> removeAccount(String uid) async {
    await _ensurePrefs();
    final normalized = uid.trim();
    if (normalized.isEmpty) return;
    accounts.removeWhere((item) => item.uid == normalized);
    if (activeUid.value == normalized) {
      activeUid.value = '';
      await _prefs?.remove(_accountCenterActiveUidStorageKey);
    }
    final lastUsedUid =
        (_prefs?.getString(_accountCenterLastUsedUidStorageKey) ?? '').trim();
    if (lastUsedUid == normalized) {
      final fallbackUid = activeUid.value.isNotEmpty
          ? activeUid.value
          : (accounts.isNotEmpty ? accounts.first.uid : '');
      this.lastUsedUid.value = fallbackUid;
      if (fallbackUid.isEmpty) {
        await _prefs?.remove(_accountCenterLastUsedUidStorageKey);
      } else {
        await _prefs?.setString(
          _accountCenterLastUsedUidStorageKey,
          fallbackUid,
        );
      }
    }
    await AccountSessionVault.instance.delete(normalized);
    await _prefs?.setString(
      _accountCenterAccountsStorageKey,
      StoredAccount.encodeList(accounts),
    );
  }

  Future<void> signOutAllLocal() async {
    accounts.clear();
    activeUid.value = '';
    lastUsedUid.value = '';
    await _ensurePrefs();
    await _prefs?.remove(_accountCenterAccountsStorageKey);
    await _prefs?.remove(_accountCenterActiveUidStorageKey);
    await _prefs?.remove(_accountCenterLastUsedUidStorageKey);
    await AccountSessionVault.instance.deleteAll();
  }
}
