import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'my_practice_exams_controller_runtime_part.dart';

class MyPracticeExamsController extends GetxController {
  static MyPracticeExamsController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(MyPracticeExamsController(), permanent: permanent);
  }

  static MyPracticeExamsController? maybeFind() {
    final isRegistered = Get.isRegistered<MyPracticeExamsController>();
    if (!isRegistered) return null;
    return Get.find<MyPracticeExamsController>();
  }

  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  final RxList<SinavModel> exams = <SinavModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapExamsImpl());
  }
}
