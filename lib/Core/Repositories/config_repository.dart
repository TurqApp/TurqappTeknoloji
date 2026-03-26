import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'config_repository_query_part.dart';
part 'config_repository_storage_part.dart';
part 'config_repository_models_part.dart';
part 'config_repository_facade_part.dart';

class ConfigRepository extends GetxService {
  static const Duration _defaultTtl = Duration(minutes: 30);
  static const String _prefsKeyPrefix = 'config_repository_v1';

  SharedPreferences? _prefs;
  final Map<String, _CachedConfigDoc> _memory = {};

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }
}
