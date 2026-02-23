import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class SearchTestsController extends GetxController {
  final list = <TestsModel>[].obs;
  final filteredList = <TestsModel>[].obs;
  final searchController = TextEditingController();
  final focusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    getData();
    Future.delayed(const Duration(milliseconds: 100), () {
      Get.focusScope?.requestFocus(focusNode);
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  Future<void> getData() async {
    list.clear();
    filteredList.clear();

    final snap = await FirebaseFirestore.instance.collection("Testler").get();

    for (var doc in snap.docs) {
      final aciklama = doc.get("aciklama") as String;
      final testTuru = doc.get("testTuru") as String;
      final dersler = List<String>.from(doc['dersler'] ?? []);
      final img = doc.get("img") as String;
      final timeStamp = doc.get("timeStamp") as String;
      final userID = doc.get("userID") as String;
      final paylasilabilir = doc.get("paylasilabilir") as bool;
      final taslak = doc.get("taslak") as bool;

      list.add(
        TestsModel(
          userID: userID,
          timeStamp: timeStamp,
          aciklama: aciklama,
          dersler: dersler,
          img: img,
          docID: doc.id,
          paylasilabilir: paylasilabilir,
          testTuru: testTuru,
          taslak: taslak,
        ),
      );
    }

    filteredList.assignAll(list);
  }

  void filterSearchResults(String query) {
    if (query.isEmpty) {
      filteredList.assignAll(list);
    } else {
      filteredList.assignAll(
        list.where(
          (test) =>
              test.aciklama.toLowerCase().contains(query.toLowerCase()) ||
              test.testTuru.toLowerCase().contains(query.toLowerCase()) ||
              test.dersler.any(
                (ders) => ders.toLowerCase().contains(query.toLowerCase()),
              ),
        ),
      );
    }
  }
}
