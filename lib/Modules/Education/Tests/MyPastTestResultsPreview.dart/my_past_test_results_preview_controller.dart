import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

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
    if (!Get.isRegistered<MyPastTestResultsPreviewController>(tag: tag)) {
      return null;
    }
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
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final cachedAnswers = await _testRepository.fetchAnswers(
      model.docID,
      cacheOnly: true,
    );
    final cachedQuestions = await _testRepository.fetchQuestions(
      model.docID,
      cacheOnly: true,
    );
    if (cachedAnswers.isNotEmpty || cachedQuestions.isNotEmpty) {
      _applyAnswers(cachedAnswers);
      soruList.assignAll(cachedQuestions);
      updateStats();
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'tests:preview:${model.docID}',
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
    if (!silent) {
      isLoading.value = true;
    }
    try {
      final yanitSnapshot = await _testRepository.fetchAnswers(
        model.docID,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      _applyAnswers(yanitSnapshot);

      final soruSnapshot = await _testRepository.fetchQuestions(
        model.docID,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      soruList.assignAll(soruSnapshot);

      updateStats();
      SilentRefreshGate.markRefreshed('tests:preview:${model.docID}');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void _applyAnswers(List<Map<String, dynamic>> snapshot) {
    yanitlar.clear();
    timeStamp.value = 0;
    for (final doc in snapshot) {
      yanitlar.assignAll(List<String>.from(doc['cevaplar'] ?? const []));
      timeStamp.value = ((doc["timeStamp"] ?? 0) as num).toInt();
    }
  }

  void updateStats() {
    dogruSayisi.value = 0;
    yanlisSayisi.value = 0;
    bosSayisi.value = 0;

    for (var i = 0; i < yanitlar.length && i < soruList.length; i++) {
      if (yanitlar[i] == "") {
        bosSayisi.value++;
      } else if (yanitlar[i] == soruList[i].dogruCevap) {
        dogruSayisi.value++;
      } else {
        yanlisSayisi.value++;
      }
    }

    totalPuan.value =
        soruList.isNotEmpty ? (100 / soruList.length) * dogruSayisi.value : 0;
  }

  Color determineChoiceColor(int index, String choice) {
    if (choice == soruList[index].dogruCevap && yanitlar[index] == "") {
      return Colors.white;
    } else if (choice == soruList[index].dogruCevap) {
      return Colors.green;
    } else if (choice == yanitlar[index]) {
      return Colors.red;
    } else {
      return Colors.white;
    }
  }

  Color determineChoiceTextColor(int index, String choice) {
    if (choice == soruList[index].dogruCevap && yanitlar[index] == "") {
      return Colors.black;
    } else if (choice == soruList[index].dogruCevap) {
      return Colors.white;
    } else if (choice == yanitlar[index]) {
      return Colors.white;
    } else {
      return Colors.black;
    }
  }
}
