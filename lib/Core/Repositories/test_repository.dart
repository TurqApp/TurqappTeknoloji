import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

part 'test_repository_query_part.dart';
part 'test_repository_action_part.dart';
part 'test_repository_cache_part.dart';
part 'test_repository_facade_part.dart';
part 'test_repository_models_part.dart';

class TestRepository extends GetxService {
  TestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'test_repository_v1';
  final Map<String, _TimedTests> _memory = <String, _TimedTests>{};
  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _handleTestRepositoryInit(this);
  }
}
