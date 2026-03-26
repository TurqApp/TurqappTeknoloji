import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'user_subdoc_repository_models_part.dart';
part 'user_subdoc_repository_cache_part.dart';
part 'user_subdoc_repository_facade_part.dart';
part 'user_subdoc_repository_runtime_part.dart';

class UserSubdocRepository extends GetxService {
  static const String _prefsPrefix = 'user_subdoc_repository_v1';
  static const Duration _defaultTtl = Duration(hours: 6);

  static UserSubdocRepository? maybeFind() => maybeFindUserSubdocRepository();

  static UserSubdocRepository ensure() => ensureUserSubdocRepository();

  SharedPreferences? _prefs;
  final Map<String, _CachedUserSubdoc> _memory = {};

  @override
  void onInit() {
    super.onInit();
    _handleUserSubdocRepositoryInit();
  }
}
