import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/ders_ve_sonuclar_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';

part 'practice_exam_repository_query_part.dart';
part 'practice_exam_repository_detail_part.dart';
part 'practice_exam_repository_models_part.dart';
part 'practice_exam_repository_lifecycle_part.dart';
part 'practice_exam_repository_cache_part.dart';
part 'practice_exam_repository_helpers_part.dart';

class PracticeExamRepository extends GetxService {
  PracticeExamRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'practice_exam_repository_v1';
  final Map<String, _TimedPracticeExams> _memory =
      <String, _TimedPracticeExams>{};
  final Map<String, _TimedPracticeExamBool> _boolMemory =
      <String, _TimedPracticeExamBool>{};
  SharedPreferences? _prefs;

  static PracticeExamRepository? maybeFind() {
    final isRegistered = Get.isRegistered<PracticeExamRepository>();
    if (!isRegistered) return null;
    return Get.find<PracticeExamRepository>();
  }

  static PracticeExamRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(PracticeExamRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    _PracticeExamRepositoryLifecyclePart(this).handleOnInit();
  }
}
