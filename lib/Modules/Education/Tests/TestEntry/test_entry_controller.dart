import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/SolveTest/solve_test.dart';

class TestEntryController extends GetxController {
  final textController = TextEditingController();
  final focusNode = FocusNode();
  final model = Rx<TestsModel?>(null);
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    focusNode.requestFocus();
  }

  @override
  void onClose() {
    textController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  void onTextChanged(String val) {
    if (val.length >= 10) {
      getTests(val);
    }
  }

  void onTextSubmitted(String val) {
    if (val.length >= 10) {
      getTests(val);
    }
  }

  Future<void> getTests(String testID) async {
    isLoading.value = true;
    try {
      final doc = await FirebaseFirestore.instance
          .collection("Testler")
          .doc(testID)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        model.value = TestsModel(
          userID: data['userID'] as String,
          timeStamp: data['timeStamp'] as String,
          aciklama: data['aciklama'] as String,
          dersler: List<String>.from(data['dersler'] ?? []),
          img: data['img'] as String,
          docID: doc.id,
          paylasilabilir: data['paylasilabilir'] as bool,
          testTuru: data['testTuru'] as String,
          taslak: data['taslak'] as bool,
        );
        print("buldu");
        closeKeyboard(Get.context!);
      } else {
        model.value = null;
        print("veriyok");
      }
    } catch (e) {
      print("Error fetching test: $e");
      model.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  void joinTest(BuildContext context) {
    if (model.value != null) {
      Get.to(
        () => SolveTest(testID: model.value!.docID, showSucces: showAlert),
      )?.then((_) {
        model.value = null;
        textController.text = "";
      });
    }
  }

  void showAlert() {
    showAlertDialog(
      Get.context!,
      "Testi Bitirdin!",
      "Sonuçlarım ekranında puanına ve doğru yanlış oranlarına bakabilirsin.",
    );
  }
}
