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

part 'account_center_service_storage_part.dart';
part 'account_center_service_accounts_part.dart';

const _accountCenterAccountsStorageKey = 'account_center.accounts';
const _accountCenterActiveUidStorageKey = 'account_center.active_uid';
const _accountCenterLastUsedUidStorageKey = 'account_center.last_used_uid';

class AccountCenterService extends GetxService {
  final RxList<StoredAccount> accounts = <StoredAccount>[].obs;
  final RxString activeUid = ''.obs;
  final RxString lastUsedUid = ''.obs;
  SharedPreferences? _prefs;
  bool _initScheduled = false;
  bool _initialized = false;
  Future<void>? _initFuture;
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
}
