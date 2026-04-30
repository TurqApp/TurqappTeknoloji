import 'dart:convert';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';

part 'config_repository_query_part.dart';
part 'config_repository_storage_part.dart';
part 'config_repository_models_part.dart';
part 'config_repository_facade_part.dart';

class ConfigRepository extends GetxService {
  static const Duration _defaultTtl = Duration(minutes: 30);
  static const String _prefsKeyPrefix = 'config_repository_v1';

  LocalPreferenceRepository? _preferences;
  final Map<String, _CachedConfigDoc> _memory = {};

  @override
  void onInit() {
    super.onInit();
    _preferences = ensureLocalPreferenceRepository();
  }
}
