import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

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

  bool _sameExamEntries(
    List<SinavModel> current,
    List<SinavModel> next,
  ) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.sinavAdi,
            item.sinavTuru,
            item.timeStamp,
            item.participantCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.sinavAdi,
            item.sinavTuru,
            item.timeStamp,
            item.participantCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapExams());
  }

  Future<void> _bootstrapExams() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      exams.clear();
      isLoading.value = false;
      return;
    }

    try {
      final cached = await _practiceExamRepository.fetchByOwner(uid);
      if (cached.isNotEmpty) {
        if (!_sameExamEntries(exams, cached)) {
          exams.assignAll(cached);
        }
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
    final uid = CurrentUserService.instance.effectiveUserId;
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
      if (!_sameExamEntries(exams, items)) {
        exams.assignAll(items);
      }
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
