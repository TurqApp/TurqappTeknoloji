import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';

class OpticalFormContentController extends GetxController {
  static OpticalFormContentController ensure(
    OpticalFormModel model, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      OpticalFormContentController(model),
      tag: tag,
      permanent: permanent,
    );
  }

  static OpticalFormContentController? maybeFind({String? tag}) {
    if (!Get.isRegistered<OpticalFormContentController>(tag: tag)) {
      return null;
    }
    return Get.find<OpticalFormContentController>(tag: tag);
  }

  final OpticalFormModel model;
  final total = 0.obs;
  final OpticalFormRepository _opticalFormRepository =
      OpticalFormRepository.ensure();

  OpticalFormContentController(this.model) {
    fetchTotal();
  }

  Future<void> fetchTotal() async {
    total.value = 0;
    total.value = await _opticalFormRepository.fetchAnswerCount(model.docID);
  }

  void copyDocID() {
    Clipboard.setData(ClipboardData(text: model.docID));
  }

  void showAlert() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "answer_key.answers_sent_title".tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratBold",
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "answer_key.answers_sent_body".tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Text(
                  "common.ok".tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: "MontserratBold",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  void showGecersizSinavAlert() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "answer_key.invalid_exam_title".tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratBold",
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "answer_key.invalid_exam_body".tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Text(
                  "common.ok".tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: "MontserratBold",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> deleteOpticalForm() async {
    try {
      await _opticalFormRepository.deleteForm(model.docID);
    } catch (_) {}
  }
}
