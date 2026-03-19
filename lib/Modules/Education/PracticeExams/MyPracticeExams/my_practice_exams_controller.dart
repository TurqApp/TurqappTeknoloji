import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class MyPracticeExamsController extends GetxController {
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  final RxList<SinavModel> exams = <SinavModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapExams());
  }

  Future<void> _bootstrapExams() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      exams.clear();
      isLoading.value = false;
      return;
    }

    try {
      final cached = await _practiceExamRepository.fetchByOwner(uid);
      if (cached.isNotEmpty) {
        exams.assignAll(cached);
        isLoading.value = false;
        if (SilentRefreshGate.shouldRefresh(
          'practice_exams:owner:$uid',
          minInterval: _silentRefreshInterval,
        )) {
          unawaited(fetchExams(silent: true, forceRefresh: true));
        }
        return;
      }
    } catch (_) {}

    await fetchExams();
  }

  Future<void> fetchExams({
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      exams.clear();
      isLoading.value = false;
      return;
    }

    final shouldShowLoader = !silent && exams.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      final items = await _practiceExamRepository.fetchByOwner(
        uid,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      exams.assignAll(items);
      SilentRefreshGate.markRefreshed('practice_exams:owner:$uid');
    } catch (e) {
      log('MyPracticeExamsController.fetchExams error: $e');
      AppSnackbar('common.error'.tr, 'tests.exams_load_failed'.tr);
    } finally {
      if (shouldShowLoader || exams.isEmpty) {
        isLoading.value = false;
      }
    }
  }
}
