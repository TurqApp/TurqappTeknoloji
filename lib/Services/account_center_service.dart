import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Utils/current_user_utils.dart';
import 'package:turqappv2/Core/Utils/email_utils.dart';
import 'package:turqappv2/Models/current_user_model.dart';
import 'package:turqappv2/Models/stored_account.dart';
import 'package:turqappv2/Services/account_session_vault.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/device_session_service.dart';

part 'account_center_service_facade_part.dart';
part 'account_center_service_fields_part.dart';
part 'account_center_service_storage_part.dart';
part 'account_center_service_accounts_part.dart';

const _accountCenterAccountsStorageKey = 'account_center.accounts';
const _accountCenterActiveUidStorageKey = 'account_center.active_uid';
const _accountCenterLastUsedUidStorageKey = 'account_center.last_used_uid';

class AccountCenterService extends GetxService {
  final _state = _AccountCenterServiceState();

  @override
  void onInit() {
    super.onInit();
    _handleAccountCenterServiceInit(this);
  }
}
