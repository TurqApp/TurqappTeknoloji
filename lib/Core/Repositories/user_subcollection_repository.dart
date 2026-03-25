import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static UserSubcollectionRepository? maybeFind() {
    final isRegistered = Get.isRegistered<UserSubcollectionRepository>();
    if (!isRegistered) return null;
    return Get.find<UserSubcollectionRepository>();
  }

  static UserSubcollectionRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(UserSubcollectionRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }
}
