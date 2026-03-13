import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class MyPastTestResultsPreviewController extends GetxController {
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
    getData();
  }

  Future<void> getData() async {
    isLoading.value = true;
    try {
      final yanitSnapshot = await _testRepository.fetchAnswers(
        model.docID,
        preferCache: true,
      );
      for (final doc in yanitSnapshot) {
        yanitlar.assignAll(List<String>.from(doc['cevaplar'] ?? const []));
        timeStamp.value = ((doc["timeStamp"] ?? 0) as num).toInt();
      }

      final soruSnapshot = await _testRepository.fetchQuestions(
        model.docID,
        preferCache: true,
      );
      soruList.clear();
      soruList.assignAll(soruSnapshot);

      updateStats();
    } catch (e) {
      print("Error fetching test results: $e");
    } finally {
      isLoading.value = false;
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
