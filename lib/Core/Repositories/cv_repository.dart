import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'cv_repository_models_part.dart';
part 'cv_repository_cache_part.dart';
part 'cv_repository_facade_part.dart';

class CvRepository extends GetxService {
  static const Duration _ttl = Duration(minutes: 30);
  static const String _prefsPrefix = 'cv_repository_v1';

  static CvRepository? maybeFind() => maybeFindCvRepository();

  static CvRepository ensure() => ensureCvRepository();

  SharedPreferences? _prefs;
  final Map<String, _CachedCv> _memory = {};

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }
}
