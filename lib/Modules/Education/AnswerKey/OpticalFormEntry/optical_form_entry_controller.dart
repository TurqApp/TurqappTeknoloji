import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticalPreview/optical_preview.dart';

class OpticalFormEntryController extends GetxController {
  final UserRepository _userRepository = UserRepository.ensure();
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
        "Sınavın süresi doldu!",
        "Aradığınız sınavın süresi dolmuştur!",
      );
      model.value = null;
    }
  }

  Future<void> getUserData(String userID) async {
    final data =
        await _userRepository.getUserRaw(userID) ?? const <String, dynamic>{};
    final firstName = (data["firstName"] ?? "").toString();
    final lastName = (data["lastName"] ?? "").toString();
    final avatarUrl = (data["avatarUrl"] ??
            data["avatarUrl"] ??
            data["avatarUrl"] ??
            data["avatarUrl"] ??
            "")
        .toString();

    fullName.value = "$firstName $lastName";
    this.avatarUrl.value = avatarUrl;
  }

  Future<void> showAlert() async {
    final currentModel = model.value;
    if (currentModel != null) {
      try {
        final userAnswers = await _opticalFormRepository.fetchUserAnswers(
          currentModel.docID,
          FirebaseAuth.instance.currentUser!.uid,
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
          "Tebrikler, Sınavı Tamamladın!",
          "Doğru: $dogru   •   Yanlış: $yanlis   •   Boş: $bos   •   Net: ${net.toStringAsFixed(2)}",
        );
      } catch (_) {
        showAlertDialog(
            "Tebrikler, Sınavı Tamamladın!", "Sonuç hesaplanamadı.");
      }
    } else {
      showAlertDialog("Tebrikler, Sınavı Tamamladın!", "Sonuç hesaplanamadı.");
    }
    model.value = null;
    search.text = "";
    searchText.value = "";
  }

  void handleExamTap(BuildContext context) {
    if (model.value!.baslangic.toInt() >
        DateTime.now().millisecondsSinceEpoch) {
      showAlertDialog(
        "Sınav Başlamadı!",
        "Sınavınız başlamadı. Başladıktan sonra tekrar deneyin!",
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
