import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Models/current_user_model.dart';
import 'package:turqappv2/Models/stored_account.dart';

class AccountCenterService extends GetxService {
  static const String _accountsKey = 'account_center.accounts';
  static const String _activeUidKey = 'account_center.active_uid';
  static const String _lastUsedUidKey = 'account_center.last_used_uid';

  final RxList<StoredAccount> accounts = <StoredAccount>[].obs;
  final RxString activeUid = ''.obs;
  final RxString lastUsedUid = ''.obs;
  SharedPreferences? _prefs;

  int _compareAccounts(StoredAccount a, StoredAccount b) {
    if (a.isPinned != b.isPinned) {
      return a.isPinned ? -1 : 1;
    }
    if (a.sortOrder != b.sortOrder) {
      return a.sortOrder.compareTo(b.sortOrder);
    }
    return b.lastUsedAt.compareTo(a.lastUsedAt);
  }

  static AccountCenterService ensure() {
    if (Get.isRegistered<AccountCenterService>()) {
      return Get.find<AccountCenterService>();
    }
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
    final restored = StoredAccount.decodeList(raw)
      ..sort(_compareAccounts);
    accounts.assignAll(restored);
    activeUid.value = (_prefs?.getString(_activeUidKey) ?? '').trim();
    lastUsedUid.value = (_prefs?.getString(_lastUsedUidKey) ?? '').trim();
    await reconcileWithAuthSession();
  }

  Future<void> reconcileWithAuthSession() async {
    await _ensurePrefs();
    final authUid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (authUid.isEmpty) {
      if (activeUid.value.isNotEmpty) {
        activeUid.value = '';
        await _prefs?.remove(_activeUidKey);
      }
      if (lastUsedUid.value.isNotEmpty && accountByUid(lastUsedUid.value) == null) {
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
    final current = accounts.toList(growable: true);
    final index = current.indexWhere((item) => item.uid == account.uid);
    var shouldPromoteActiveUid = promoteActiveUid;
    if (index >= 0) {
      final existing = current[index];
      current[index] = account.copyWith(
        isPinned: account.isPinned,
        sortOrder: account.sortOrder == 0 ? existing.sortOrder : account.sortOrder,
        lastSuccessfulSignInAt: account.lastSuccessfulSignInAt == 0
            ? existing.lastSuccessfulSignInAt
            : account.lastSuccessfulSignInAt,
      );
      shouldPromoteActiveUid = promoteActiveUid && account.isSessionValid;
    } else {
      final nextSortOrder = current.isEmpty
          ? 1
          : current
                  .map((item) => item.sortOrder)
                  .reduce((value, element) => value > element ? value : element) +
              1;
      current.add(account.copyWith(sortOrder: account.sortOrder == 0 ? nextSortOrder : account.sortOrder));
      shouldPromoteActiveUid = promoteActiveUid && account.isSessionValid;
    }
    current.sort(_compareAccounts);
    accounts.assignAll(current);
    if (shouldPromoteActiveUid) {
      activeUid.value = account.uid;
      lastUsedUid.value = account.uid;
    }
    await _persist();
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
  }
}
