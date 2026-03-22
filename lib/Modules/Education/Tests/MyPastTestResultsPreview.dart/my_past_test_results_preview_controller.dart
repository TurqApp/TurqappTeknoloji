import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

part 'my_past_test_results_preview_controller_data_part.dart';
part 'my_past_test_results_preview_controller_ui_part.dart';

class MyPastTestResultsPreviewController extends GetxController {
  static MyPastTestResultsPreviewController ensure(
    TestsModel model, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyPastTestResultsPreviewController(model),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyPastTestResultsPreviewController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<MyPastTestResultsPreviewController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyPastTestResultsPreviewController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final TestsModel model;
  final yanitlar = <String>[].obs;
  final timeStamp = 0.obs;
  final soruList = <TestReadinessModel>[].obs;
  final dogruSayisi = 0.obs;
  final yanlisSayisi = 0.obs;
  final bosSayisi = 0.obs;
  final totalPuan = 0.0.obs;
  final isLoading = true.obs;
  final TestRepository _testRepository = TestRepository.ensure();

  MyPastTestResultsPreviewController(this.model);

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }
}
