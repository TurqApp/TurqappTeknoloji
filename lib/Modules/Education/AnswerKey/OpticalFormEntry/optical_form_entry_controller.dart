import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticalPreview/optical_preview.dart';

class OpticalFormEntryController extends GetxController {
  final search = TextEditingController();
  final focusNode = FocusNode();
  final searchText = ''.obs; // Reactive search text
  final model = Rx<OpticalFormModel?>(null);
  final fullName = ''.obs;
  final pfImage = ''.obs;

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
    final doc = await FirebaseFirestore.instance
        .collection("optikForm")
        .doc(search.text)
        .get();

    if (!doc.exists) return;

    final cevaplar = List<String>.from(doc.get("cevaplar") ?? []);
    final max = doc.get("max") as num;
    final bitis = doc.get("bitis") as num;
    final baslangic = doc.get("baslangic") as num;
    final name = doc.get("name") as String;
    final userID = doc.get("userID") as String;
    final kisitlama = doc.get("kisitlama") as bool;

    if (bitis.toInt() > DateTime.now().millisecondsSinceEpoch) {
      focusNode.unfocus();
      model.value = OpticalFormModel(
        docID: doc.id,
        name: name,
        cevaplar: cevaplar,
        max: max,
        userID: userID,
        baslangic: baslangic,
        bitis: bitis,
        kisitlama: kisitlama,
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
    final doc =
        await FirebaseFirestore.instance.collection("users").doc(userID).get();
    final data = doc.data() ?? const <String, dynamic>{};
    final firstName = (data["firstName"] ?? "").toString();
    final lastName = (data["lastName"] ?? "").toString();
    final pfImage = (data["avatarUrl"] ??
            data["pfImage"] ??
            data["photoURL"] ??
            data["profileImageUrl"] ??
            "")
        .toString();

    fullName.value = "$firstName $lastName";
    this.pfImage.value = pfImage;
  }

  Future<void> showAlert() async {
    final currentModel = model.value;
    if (currentModel != null) {
      try {
        final yanitDoc = await FirebaseFirestore.instance
            .collection("optikForm")
            .doc(currentModel.docID)
            .collection("Yanitlar")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();

        final userAnswers = List<String>.from(yanitDoc.get("cevaplar") ?? []);
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
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratBold",
                ),
              ),
              const SizedBox(height: 10),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: const TextStyle(
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
                  child: const Text(
                    "Tamam",
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
      ),
    );
  }
}
