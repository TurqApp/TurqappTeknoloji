import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/CreateAnswerKey/CreateAnswerKey.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/CreateBook/CreateBook.dart';

class AnswerKeyCreatingOptionController extends GetxController {
  final Function onBack;

  AnswerKeyCreatingOptionController(this.onBack);

  void navigateToCreateAnswerKey(BuildContext context) {
    Get.to(
      () => CreateAnswerKey(
        onBack: () {
          onBack();
          Get.back();
        },
      ),
    )?.then((_) => Get.back());
  }

  void navigateToCreateBook(BuildContext context) {
    Get.to(
      () => CreateBook(
        onBack: () {
          onBack();
          Get.back();
        },
      ),
    )?.then((_) => Get.back());
  }
}
