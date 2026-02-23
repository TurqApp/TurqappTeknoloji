import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  MyPastTestResultsPreviewController(this.model);

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  Future<void> getData() async {
    isLoading.value = true;
    try {
      // Fetch answers
      final yanitSnapshot =
          await FirebaseFirestore.instance
              .collection("Testler")
              .doc(model.docID)
              .collection("Yanitlar")
              .get();

      for (var doc in yanitSnapshot.docs) {
        yanitlar.assignAll(List<String>.from(doc['cevaplar']));
        timeStamp.value = doc.get("timeStamp");
      }

      // Fetch questions
      final soruSnapshot =
          await FirebaseFirestore.instance
              .collection("Testler")
              .doc(model.docID)
              .collection("Sorular")
              .orderBy("id", descending: false)
              .get();

      soruList.clear();
      for (var doc in soruSnapshot.docs) {
        final img = doc.get("img") as String;
        final id = doc.get("id") as num;
        final dogruCevap = doc.get("dogruCevap") as String;
        final max = doc.get("max") as num;

        soruList.add(
          TestReadinessModel(
            id: id.toInt(),
            img: img,
            max: max.toInt(),
            dogruCevap: dogruCevap,
            docID: doc.id,
          ),
        );
      }

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
