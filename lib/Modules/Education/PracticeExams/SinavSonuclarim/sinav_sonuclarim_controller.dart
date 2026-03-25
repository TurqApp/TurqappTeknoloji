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

part 'sinav_sonuclarim_controller_runtime_part.dart';

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

  @override
  void onInit() {
    super.onInit();
    scrolControlcu();
    unawaited(_SinavSonuclarimControllerRuntimeX(this).bootstrapData());
  }

  void scrolControlcu() =>
      _SinavSonuclarimControllerRuntimeX(this).setupScrollController();

  Future<void> findAndGetSinavlar({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _SinavSonuclarimControllerRuntimeX(this).findAndGetSinavlar(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
