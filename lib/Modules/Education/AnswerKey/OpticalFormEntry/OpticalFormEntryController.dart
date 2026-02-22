import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/OpticalFormModel.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticalPreview/OpticalPreview.dart';

class OpticalFormEntryController extends GetxController {
  final search = TextEditingController();
  final focusNode = FocusNode();
  final searchText = ''.obs; // Reactive search text
  final model = Rx<OpticalFormModel?>(null);
  final fullName = ''.obs;
  final pfImage = ''.obs;
  final sinavaGirdi = false.obs;

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
    final doc =
        await FirebaseFirestore.instance
            .collection("OptikKodlar")
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
      ogrenciSinavaGirdiMi(doc.id);
    } else {
      focusNode.unfocus();
      showAlertDialog(
        "Sınavın süresi doldu!",
        "Aradığınız sınavın süresi dolmuştur!",
      );
      model.value = null;
    }
  }

  Future<void> ogrenciSinavaGirdiMi(String docID) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection("OptikKodlar")
              .doc(docID)
              .collection("Yanitlar")
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get();

      if (doc.exists) {
        print("Doküman mevcut: Öğrenci sınava girmiş.");
        sinavaGirdi.value = model.value!.kisitlama;
      } else {
        print("Doküman mevcut değil: Öğrenci sınava girmemiş.");
        sinavaGirdi.value = false;
      }
    } catch (error) {
      print("Hata oluştu: $error");
      sinavaGirdi.value = false;
    }
  }

  Future<void> getUserData(String userID) async {
    final doc =
        await FirebaseFirestore.instance
            .collection("users")
            .doc(userID)
            .get();
    final firstName = doc.get("firstName") as String;
    final lastName = doc.get("lastName") as String;
    final pfImage = doc.get("pfImage") as String;

    fullName.value = "$firstName $lastName";
    this.pfImage.value = pfImage;
  }

  void showAlert() {
    showAlertDialog(
      "Tebrikler, Sınavı Tamamladın!",
      "Sınavı başarıyla tamamladın. Sonuçlarını görmek için 'Sonuçlar' sayfasına göz atabilirsin.",
    );
    model.value = null;
    search.text = "";
    searchText.value = "";
  }

  void showGecersizSinavAlert() {
    showAlertDialog(
      "Sınavınız Geçersiz Sayılmıştır!",
      "Sizi uyardık! Kural ihlali yaptığınız için sınavınız geçersiz sayılmıştır!",
    );
  }

  void handleExamTap(BuildContext context) {
    if (model.value!.baslangic.toInt() >
        DateTime.now().millisecondsSinceEpoch) {
      showAlertDialog(
        "Sınav Başlamadı!",
        "Sınavınız başlamadı. Başladıktan sonra tekrar deneyin!",
      );
    } else if (!sinavaGirdi.value) {
      Get.to(
        () => WillPopScope(
          onWillPop: () async {
            bool canExit = false;

            await Get.bottomSheet(
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
                      const Text(
                        "Sınavdan çıkmak mı istiyorsunuz?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        model.value!.kisitlama
                            ? "Tüm cevaplarınız geçersiz sayılacaktır!"
                            : "Tüm cevaplarınız geçersiz sayılacaktır!",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          if (model.value!.kisitlama) {
                            final gecersizList = List.filled(
                              model.value!.cevaplar.length,
                              "",
                            );
                            FirebaseFirestore.instance
                                .collection("OptikKodlar")
                                .doc(model.value!.docID)
                                .collection("Yanitlar")
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .update({
                                  "timeStamp":
                                      DateTime.now().millisecondsSinceEpoch,
                                  "cevaplar": gecersizList,
                                });
                            model.value = null;
                            searchDocID();
                          } else {
                            model.value = null;
                          }
                          Get.back();
                          canExit = true;
                        },
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: const Text(
                            "Sınavdan Çık",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Get.back();
                          canExit = false;
                        },
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: const Text(
                            "Burada Kal",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            return canExit;
          },
          child: OpticalPreview(
            model: model.value!,
            update: showAlert,
            gecersizSay: showGecersizSinavAlert,
          ),
        ),
      );
    } else {
      showAlertDialog(
        "Sınava Giremezsin!",
        "Daha önce bu sınava girdin. Bir sınava sadece bir kez girebilirsin",
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
