import 'dart:developer';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class SinavSonuclarimController extends GetxController {
  static SinavSonuclarimController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(SinavSonuclarimController(), permanent: permanent);
  }

  static SinavSonuclarimController? maybeFind() {
    final isRegistered = Get.isRegistered<SinavSonuclarimController>();
    if (!isRegistered) return null;
    return Get.find<SinavSonuclarimController>();
  }

  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  var list = <SinavModel>[].obs;
  var ustBar = true.obs;
  var isLoading = true.obs;
  final ScrollController scrollController = ScrollController();
  double _previousOffset = 0.0;

  bool _sameExamEntries(List<SinavModel> current, List<SinavModel> next) {
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
    scrolControlcu();
    unawaited(_bootstrapData());
  }

  void scrolControlcu() {
    scrollController.addListener(() {
      double currentOffset = scrollController.position.pixels;

      if (currentOffset > _previousOffset) {
        if (ustBar.value) ustBar.value = false;
      } else if (currentOffset < _previousOffset) {
        if (!ustBar.value) ustBar.value = true;
      }

      _previousOffset = currentOffset;
    });
  }

  Future<void> _bootstrapData() async {
    final currentUserID = CurrentUserService.instance.effectiveUserId;
    if (currentUserID.isEmpty) return;
    final cached = await _practiceExamRepository.fetchAnsweredByUser(
      currentUserID,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      if (!_sameExamEntries(list, cached)) {
        list.assignAll(cached);
      }
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'practice_exams:results:$currentUserID',
        minInterval: _silentRefreshInterval,
      )) {
        unawaited(findAndGetSinavlar(silent: true, forceRefresh: true));
      }
      return;
    }
    await findAndGetSinavlar();
  }

  Future<void> findAndGetSinavlar({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent || list.isEmpty) {
      isLoading.value = true;
    }
    try {
      final currentUserID = CurrentUserService.instance.effectiveUserId;
      final exams = await _practiceExamRepository.fetchAnsweredByUser(
        currentUserID,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      if (!_sameExamEntries(list, exams)) {
        list.assignAll(exams);
      }
      SilentRefreshGate.markRefreshed('practice_exams:results:$currentUserID');
    } catch (e) {
      log("SinavSonuclarimController error: $e");
      AppSnackbar('common.error'.tr, 'tests.results_load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
