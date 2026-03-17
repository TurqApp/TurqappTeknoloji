import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class DenemeTurleriListesiController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  var list = <SinavModel>[].obs;
  var isLoading = false.obs;
  var isInitialized = false.obs;

  final String sinavTuru;
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();

  DenemeTurleriListesiController({required this.sinavTuru});

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
      list.assignAll(cached);
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
      list.assignAll(items);
      SilentRefreshGate.markRefreshed('practice_exams:type:$sinavTuru');
    } catch (error) {
      AppSnackbar("Hata", "Sınavlar yüklenemedi.");
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }
}
