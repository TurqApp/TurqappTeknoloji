import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/CreateTest/create_test_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/SolveTest/solve_test.dart';

class TestEntryController extends GetxController {
  final textController = TextEditingController();
  final focusNode = FocusNode();
  final model = Rx<TestsModel?>(null);
  final isLoading = false.obs;
  final TestRepository _testRepository = TestRepository.ensure();
  final _helper = CreateTestController(null);

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
      final data = await _testRepository.fetchRawById(
        testID,
        preferCache: true,
      );
      if (data != null) {
        model.value = TestsModel(
          userID: data['userID'] as String,
          timeStamp: data['timeStamp'] as String,
          aciklama: data['aciklama'] as String,
          dersler: List<String>.from(data['dersler'] ?? []),
          img: data['img'] as String,
          docID: testID,
          paylasilabilir: data['paylasilabilir'] as bool,
          testTuru: data['testTuru'] as String,
          taslak: data['taslak'] as bool,
        );
        closeKeyboard(Get.context!);
      } else {
        model.value = null;
      }
    } catch (e) {
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

  String localizedTestType(String raw) => _helper.localizedTestType(raw);

  String localizedLessons(List<String> lessons) => _helper.localizedLessons(lessons);

  void showAlert() {
    showAlertDialog(
      Get.context!,
      "tests.completed_title".tr,
      "tests.completed_body".tr,
    );
  }
}
