import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'verified_account_repository_models_part.dart';
part 'verified_account_repository_cache_part.dart';
part 'verified_account_repository_facade_part.dart';
part 'verified_account_repository_runtime_part.dart';

class VerifiedAccountRepository extends GetxService {
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'verified_account_repository_v2';

  SharedPreferences? _prefs;
  final Map<String, _CachedVerifiedAccountStatus> _memory = {};

  @override
  void onInit() {
    super.onInit();
    ensureLocalPreferenceRepository().sharedPreferences().then((prefs) {
      _prefs = prefs;
    });
  }
}
