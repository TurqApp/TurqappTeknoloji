import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';

part 'user_subcollection_repository_models_part.dart';
part 'user_subcollection_repository_facade_part.dart';
part 'user_subcollection_repository_query_part.dart';
part 'user_subcollection_repository_action_part.dart';
part 'user_subcollection_repository_storage_part.dart';

class UserSubcollectionRepository extends GetxService {
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'user_subcollection_repository_v1';

  SharedPreferences? _prefs;
  final Map<String, _CachedUserSubcollection> _memory = {};

  @override
  void onInit() {
    super.onInit();
    ensureLocalPreferenceRepository().sharedPreferences().then((prefs) {
      _prefs = prefs;
    });
  }
}
