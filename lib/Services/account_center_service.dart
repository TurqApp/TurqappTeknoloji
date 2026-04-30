import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Utils/current_user_utils.dart';
import 'package:turqappv2/Core/Utils/email_utils.dart';
import 'package:turqappv2/Core/Utils/stored_account_reauth_policy.dart';
import 'package:turqappv2/Models/current_user_model.dart';
import 'package:turqappv2/Models/stored_account.dart';
import 'package:turqappv2/Services/account_session_vault.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/device_session_service.dart';

part 'account_center_service_storage_part.dart';
part 'account_center_service_accounts_part.dart';

const _accountCenterAccountsStorageKey = 'account_center.accounts';
const _accountCenterActiveUidStorageKey = 'account_center.active_uid';
const _accountCenterLastUsedUidStorageKey = 'account_center.last_used_uid';

class _AccountCenterServiceState {
  final accounts = <StoredAccount>[].obs;
  final activeUid = ''.obs;
  final lastUsedUid = ''.obs;
  SharedPreferences? prefs;
  bool initScheduled = false;
  bool initialized = false;
  Future<void>? initFuture;
  final userSummaryResolver = UserSummaryResolver.ensure();
}

class AccountCenterService extends GetxService {
  final _state = _AccountCenterServiceState();

  @override
  void onInit() {
    super.onInit();
    _handleAccountCenterServiceInit(this);
  }
}

AccountCenterService? maybeFindAccountCenterService() =>
    _maybeFindAccountCenterService();

AccountCenterService ensureAccountCenterService() =>
    _ensureAccountCenterService();

AccountCenterService? _maybeFindAccountCenterService() {
  final isRegistered = Get.isRegistered<AccountCenterService>();
  if (!isRegistered) return null;
  return Get.find<AccountCenterService>();
}

AccountCenterService _ensureAccountCenterService() {
  final existing = _maybeFindAccountCenterService();
  if (existing != null) return existing;
  return Get.put(AccountCenterService(), permanent: true);
}

void _handleAccountCenterServiceInit(AccountCenterService controller) {
  if (controller._initScheduled) return;
  controller._initScheduled = true;
  unawaited(controller.init());
}

extension AccountCenterServiceFieldsPart on AccountCenterService {
  RxList<StoredAccount> get accounts => _state.accounts;
  RxString get activeUid => _state.activeUid;
  RxString get lastUsedUid => _state.lastUsedUid;
  SharedPreferences? get _prefs => _state.prefs;
  set _prefs(SharedPreferences? value) => _state.prefs = value;
  bool get _initScheduled => _state.initScheduled;
  set _initScheduled(bool value) => _state.initScheduled = value;
  bool get _initialized => _state.initialized;
  set _initialized(bool value) => _state.initialized = value;
  Future<void>? get _initFuture => _state.initFuture;
  set _initFuture(Future<void>? value) => _state.initFuture = value;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
}

extension AccountCenterServiceFacadePart on AccountCenterService {
  bool get _shouldLogDebug => kDebugMode && !IntegrationTestMode.enabled;

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
}
