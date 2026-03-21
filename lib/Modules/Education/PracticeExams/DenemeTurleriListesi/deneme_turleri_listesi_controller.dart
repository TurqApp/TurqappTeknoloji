import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class DenemeTurleriListesiController extends GetxController {
  static DenemeTurleriListesiController ensure({
    required String tag,
    required String sinavTuru,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      DenemeTurleriListesiController(sinavTuru: sinavTuru),
      tag: tag,
      permanent: permanent,
    );
  }

  static DenemeTurleriListesiController? maybeFind({required String tag}) {
    final isRegistered =
        Get.isRegistered<DenemeTurleriListesiController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<DenemeTurleriListesiController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  var list = <SinavModel>[].obs;
  var isLoading = false.obs;
  var isInitialized = false.obs;

  final String sinavTuru;
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();

  DenemeTurleriListesiController({required this.sinavTuru});

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
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final cached = await _practiceExamRepository.fetchByExamType(
      sinavTuru,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      if (!_sameExamEntries(list, cached)) {
        list.assignAll(cached);
      }
      isLoading.value = false;
      isInitialized.value = true;
      if (SilentRefreshGate.shouldRefresh(
        'practice_exams:type:$sinavTuru',
        minInterval: _silentRefreshInterval,
      )) {
        unawaited(getData(silent: true, forceRefresh: true));
      }
      return;
    }
    await getData();
  }

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent || list.isEmpty) {
      isLoading.value = true;
    }
    try {
      final items = await _practiceExamRepository.fetchByExamType(
        sinavTuru,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      if (!_sameExamEntries(list, items)) {
        list.assignAll(items);
      }
      SilentRefreshGate.markRefreshed('practice_exams:type:$sinavTuru');
    } catch (error) {
      AppSnackbar('common.error'.tr, 'tests.exams_load_failed'.tr);
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }
}
