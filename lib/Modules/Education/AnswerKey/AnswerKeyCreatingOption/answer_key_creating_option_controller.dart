import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/CreateAnswerKey/create_answer_key.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/CreateBook/create_book.dart';

class AnswerKeyCreatingOptionController extends GetxController {
  static AnswerKeyCreatingOptionController ensure(
    Function onBack, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      AnswerKeyCreatingOptionController(onBack),
      tag: tag,
      permanent: permanent,
    );
  }

  static AnswerKeyCreatingOptionController? maybeFind({String? tag}) {
    if (!Get.isRegistered<AnswerKeyCreatingOptionController>(tag: tag)) {
      return null;
    }
    return Get.find<AnswerKeyCreatingOptionController>(tag: tag);
  }

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
