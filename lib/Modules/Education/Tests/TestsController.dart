import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/TestsModel.dart';

class TestsController extends GetxController {
  final list = <TestsModel>[].obs;
  final showButtons = false.obs;
  final ustBar = true.obs;
  final scrollController = ScrollController();
  final _previousOffset = 0.0.obs;
  final isLoading = true.obs;
  final RxDouble scrollOffset = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    getData();
    _scrollControl();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _scrollControl() {
    scrollController.addListener(() {
      final currentOffset = scrollController.position.pixels;

      if (currentOffset > _previousOffset.value) {
        if (showButtons.value) {
          showButtons.value = false;
        }
        ustBar.value = false;
      } else if (currentOffset < _previousOffset.value) {
        if (showButtons.value) {
          showButtons.value = false;
        }
        ustBar.value = true;
      }

      _previousOffset.value = currentOffset;
    });
  }

  Future<void> getData() async {
    isLoading.value = true;
    list.clear();
    try {
      final snap = await FirebaseFirestore.instance
          .collection("Testler")
          .where("paylasilabilir", isEqualTo: true)
          .get();

      final tempList = <TestsModel>[];

      for (var doc in snap.docs) {
        final aciklama = doc.get("aciklama") as String;
        final testTuru = doc.get("testTuru") as String;
        final dersler = List<String>.from(doc['dersler'] ?? []);
        final img = doc.get("img") as String;
        final timeStamp = doc.get("timeStamp") as String;
        final userID = doc.get("userID") as String;
        final paylasilabilir = doc.get("paylasilabilir") as bool;
        final taslak = doc.get("taslak") as bool;

        tempList.add(
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

      tempList.sort(
        (a, b) =>
            int.tryParse(
              b.timeStamp,
            )?.compareTo(int.tryParse(a.timeStamp) ?? 0) ??
            0,
      );

      list.addAll(tempList);
    } finally {
      isLoading.value = false;
    }
  }
}
