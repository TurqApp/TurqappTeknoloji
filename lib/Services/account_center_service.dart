import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Utils/current_user_utils.dart';
import 'package:turqappv2/Core/Utils/email_utils.dart';
import 'package:turqappv2/Models/current_user_model.dart';
import 'package:turqappv2/Models/stored_account.dart';
import 'package:turqappv2/Services/account_session_vault.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/device_session_service.dart';

class AccountCenterService extends GetxService {
  static const String _accountsKey = 'account_center.accounts';
  static const String _activeUidKey = 'account_center.active_uid';
  static const String _lastUsedUidKey = 'account_center.last_used_uid';

  final RxList<StoredAccount> accounts = <StoredAccount>[].obs;
  final RxString activeUid = ''.obs;
  final RxString lastUsedUid = ''.obs;
  SharedPreferences? _prefs;
  bool _initScheduled = false;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  @override
  void onInit() {
    super.onInit();
    if (_initScheduled) return;
    _initScheduled = true;
    unawaited(init());
  }

  int _compareAccounts(StoredAccount a, StoredAccount b) {
    final active = activeUid.value.trim();
    if (active.isNotEmpty) {
      final aIsActive = a.uid == active;
      final bIsActive = b.uid == active;
      if (aIsActive != bIsActive) {
        return aIsActive ? -1 : 1;
      }
    }
    if (a.isPinned != b.isPinned) {
      return a.isPinned ? -1 : 1;
    }
    if (a.sortOrder != b.sortOrder) {
      return a.sortOrder.compareTo(b.sortOrder);
    }
    return b.lastUsedAt.compareTo(a.lastUsedAt);
  }

  static AccountCenterService? maybeFind() {
    final isRegistered = Get.isRegistered<AccountCenterService>();
    if (!isRegistered) return null;
    return Get.find<AccountCenterService>();
  }

  static AccountCenterService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AccountCenterService(), permanent: true);
  }

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
    await _ensurePrefs();
    final raw = _prefs?.getString(_accountsKey) ?? '';
    final restored = _dedupeAccounts(
      StoredAccount.decodeList(raw).toList(growable: true),
    )..sort(_compareAccounts);
    if (kDebugMode) {
      debugPrint(
        '[AccountCenter] init rawLength=${raw.length} restored=${restored.map((e) => e.uid).toList()}',
      );
    }
    accounts.assignAll(restored);
    activeUid.value = (_prefs?.getString(_activeUidKey) ?? '').trim();
    lastUsedUid.value = (_prefs?.getString(_lastUsedUidKey) ?? '').trim();
    await _rehydrateMissingEmails();
    await reconcileWithAuthSession();
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
        await _prefs?.remove(_activeUidKey);
      }
      if (lastUsedUid.value.isNotEmpty &&
          accountByUid(lastUsedUid.value) == null) {
        lastUsedUid.value = accounts.isNotEmpty ? accounts.first.uid : '';
      }
      if (lastUsedUid.value.isEmpty) {
        await _prefs?.remove(_lastUsedUidKey);
      } else {
        await _prefs?.setString(_lastUsedUidKey, lastUsedUid.value);
      }
      return;
    }
    if (activeUid.value == authUid) return;
    activeUid.value = authUid;
    await _prefs?.setString(_activeUidKey, authUid);
    if (lastUsedUid.value.isEmpty || accountByUid(lastUsedUid.value) == null) {
      lastUsedUid.value = authUid;
      await _prefs?.setString(_lastUsedUidKey, authUid);
    }
  }

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
      current.add(account.copyWith(
          sortOrder:
              account.sortOrder == 0 ? nextSortOrder : account.sortOrder));
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
      await _prefs?.remove(_activeUidKey);
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
    if (siblingTargetIndex < 0 || siblingTargetIndex >= siblings.length) return;
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
      await _prefs?.remove(_activeUidKey);
    }
    final lastUsedUid = (_prefs?.getString(_lastUsedUidKey) ?? '').trim();
    if (lastUsedUid == normalized) {
      final fallbackUid = activeUid.value.isNotEmpty
          ? activeUid.value
          : (accounts.isNotEmpty ? accounts.first.uid : '');
      this.lastUsedUid.value = fallbackUid;
      if (fallbackUid.isEmpty) {
        await _prefs?.remove(_lastUsedUidKey);
      } else {
        await _prefs?.setString(_lastUsedUidKey, fallbackUid);
      }
    }
    await AccountSessionVault.instance.delete(normalized);
    await _prefs?.setString(_accountsKey, StoredAccount.encodeList(accounts));
  }

  Future<void> signOutAllLocal() async {
    accounts.clear();
    activeUid.value = '';
    lastUsedUid.value = '';
    await _ensurePrefs();
    await _prefs?.remove(_accountsKey);
    await _prefs?.remove(_activeUidKey);
    await _prefs?.remove(_lastUsedUidKey);
    await AccountSessionVault.instance.deleteAll();
  }

  Future<void> _persist() async {
    await _prefs?.setString(_accountsKey, StoredAccount.encodeList(accounts));
    if (activeUid.value.isNotEmpty) {
      await _prefs?.setString(_activeUidKey, activeUid.value);
    } else {
      await _prefs?.remove(_activeUidKey);
    }
    if (lastUsedUid.value.isNotEmpty) {
      await _prefs?.setString(_lastUsedUidKey, lastUsedUid.value);
    } else {
      await _prefs?.remove(_lastUsedUidKey);
    }
    if (kDebugMode) {
      final stored = _prefs?.getString(_accountsKey) ?? '';
      debugPrint(
        '[AccountCenter] persist storedLength=${stored.length} '
        'accounts=${accounts.map((e) => e.uid).toList()}',
      );
    }
  }
}
