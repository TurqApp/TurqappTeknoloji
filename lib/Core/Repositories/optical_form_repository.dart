import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';

part 'optical_form_repository_cache_part.dart';
part 'optical_form_repository_models_part.dart';
part 'optical_form_repository_query_part.dart';
part 'optical_form_repository_action_part.dart';

class OpticalFormRepository extends GetxService {
  OpticalFormRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'optical_form_repository_v1';
  final Map<String, _TimedValue<dynamic>> _memory =
      <String, _TimedValue<dynamic>>{};
  SharedPreferences? _prefs;

  static OpticalFormRepository? maybeFind() {
    final isRegistered = Get.isRegistered<OpticalFormRepository>();
    if (!isRegistered) return null;
    return Get.find<OpticalFormRepository>();
  }

  static OpticalFormRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(OpticalFormRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }
}
