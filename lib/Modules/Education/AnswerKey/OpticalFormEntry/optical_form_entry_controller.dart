import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticalPreview/optical_preview.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class OpticalFormEntryController extends GetxController {
  static OpticalFormEntryController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      OpticalFormEntryController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static OpticalFormEntryController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<OpticalFormEntryController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<OpticalFormEntryController>(tag: tag);
  }

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final OpticalFormRepository _opticalFormRepository =
      OpticalFormRepository.ensure();
  final search = TextEditingController();
  final focusNode = FocusNode();
  final searchText = ''.obs; // Reactive search text
  final model = Rx<OpticalFormModel?>(null);
  final fullName = ''.obs;
  final avatarUrl = ''.obs;

  @override
  void onInit() {
    // Sync TextEditingController with searchText
    search.addListener(() {
      searchText.value = search.text;
    });
    super.onInit();
  }

  @override
  void onClose() {
    search.dispose();
    focusNode.dispose();
    super.onClose();
  }

  Future<void> searchDocID() async {
    final opticalForm = await _opticalFormRepository.fetchById(search.text);
    if (opticalForm == null) return;

    final bitis = opticalForm.bitis;
    final baslangic = opticalForm.baslangic;
    final userID = opticalForm.userID;

    if (bitis.toInt() > DateTime.now().millisecondsSinceEpoch) {
      focusNode.unfocus();
      model.value = OpticalFormModel(
        docID: opticalForm.docID,
        name: opticalForm.name,
        cevaplar: opticalForm.cevaplar,
        max: opticalForm.max,
        userID: opticalForm.userID,
        baslangic: baslangic,
        bitis: bitis,
        kisitlama: opticalForm.kisitlama,
      );
      getUserData(userID);
    } else {
      focusNode.unfocus();
      showAlertDialog(
        "answer_key.exam_expired_title".tr,
        "answer_key.exam_expired_body".tr,
      );
      model.value = null;
    }
  }

  Future<void> getUserData(String userID) async {
    final data = await _userSummaryResolver.resolve(
      userID,
      preferCache: true,
    );
    fullName.value = data?.displayName.trim() ?? '';
    avatarUrl.value = data?.avatarUrl ?? '';
  }

  Future<void> showAlert() async {
    final currentModel = model.value;
    if (currentModel != null) {
      try {
        final userAnswers = await _opticalFormRepository.fetchUserAnswers(
          currentModel.docID,
          CurrentUserService.instance.userId,
          forceRefresh: true,
        );
        final answerKey = currentModel.cevaplar;

        int dogru = 0;
        int yanlis = 0;
        int bos = 0;

        final len = userAnswers.length < answerKey.length
            ? userAnswers.length
            : answerKey.length;
        for (var i = 0; i < len; i++) {
          final selected = userAnswers[i];
          final correct = answerKey[i];
          if (selected.isEmpty) {
            bos++;
          } else if (selected == correct) {
            dogru++;
          } else {
            yanlis++;
          }
        }
        if (answerKey.length > userAnswers.length) {
          bos += answerKey.length - userAnswers.length;
        }

        final net = dogru - (yanlis * 0.25);
        showAlertDialog(
          "tests.completed_title".tr,
          "tests.result_breakdown".trParams({
            "correct": "$dogru",
            "wrong": "$yanlis",
            "blank": "$bos",
            "net": net.toStringAsFixed(2),
          }),
        );
      } catch (_) {
        showAlertDialog(
          "tests.completed_title".tr,
          "tests.result_unavailable".tr,
        );
      }
    } else {
      showAlertDialog(
        "tests.completed_title".tr,
        "tests.result_unavailable".tr,
      );
    }
    model.value = null;
    search.text = "";
    searchText.value = "";
  }

  void handleExamTap(BuildContext context) {
    if (model.value!.baslangic.toInt() >
        DateTime.now().millisecondsSinceEpoch) {
      showAlertDialog(
        "answer_key.exam_not_started_title".tr,
        "answer_key.exam_not_started_body".tr,
      );
    } else {
      Get.to(
        () => OpticalPreview(
          model: model.value!,
          update: showAlert,
        ),
      );
    }
  }

  void copyDocID() {
    Clipboard.setData(ClipboardData(text: model.value!.docID));
  }

  void showAlertDialog(String title, String desc) {
    infoAlert(
      title: title,
      message: desc,
    );
  }
}
