import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';

class OpticalPreviewController extends GetxController {
  final OpticalFormModel model;
  final Function? onUpdate;
  final OpticalFormRepository _opticalFormRepository =
      OpticalFormRepository.ensure();

  final cevaplar = <String>[].obs;
  final isConnected = true.obs;
  final selection = 0.obs;
  final fullName = TextEditingController();
  final ogrenciNo = TextEditingController();

  OpticalPreviewController(this.model, this.onUpdate) {
    _initialize();
  }

  void _initialize() {
    cevaplar.value = List.generate(model.cevaplar.length, (index) => "");
    kullaniciyiSinavGirdiKaydet();
    checkInternetConnection();
  }

  @override
  void onClose() {
    fullName.dispose();
    ogrenciNo.dispose();
    super.onClose();
  }

  void checkInternetConnection() {
    Connectivity().onConnectivityChanged.listen((results) {
      isConnected.value = results.any((r) => r != ConnectivityResult.none);
      print(
        isConnected.value
            ? "İnternet bağlantısı var."
            : "İnternet bağlantısı yok.",
      );
    });
  }

  void setData() {
    _opticalFormRepository
        .saveUserAnswers(
          model.docID,
          FirebaseAuth.instance.currentUser!.uid,
          answers: cevaplar.toList(growable: false),
          ogrenciNo: ogrenciNo.text,
          fullName: fullName.text,
        )
        .then((_) => Get.back());
  }

  void kullaniciyiSinavGirdiKaydet() {
    _opticalFormRepository.initializeUserAnswers(
      model.docID,
      FirebaseAuth.instance.currentUser!.uid,
      model.cevaplar.length,
    );
  }

  void toggleAnswer(int index, String item) {
    if (cevaplar[index] == item) {
      cevaplar[index] = "";
    } else {
      cevaplar[index] = item;
    }
  }

  void handleFinishTest(BuildContext context) {
    if (isConnected.value) {
      setData();
    } else {
      showAlertDialog(
        "İnternet bağlantınızı açın!",
        "Sınavı bitirmek istiyor iseniz internet bağlantınızı açınız",
      );
    }
  }

  void startTest() {
    selection.value = 1;
  }

  bool canStartTest() {
    return fullName.text.trim().length >= 6 && ogrenciNo.text.trim().isNotEmpty;
  }

  void showAlertDialog(String title, String desc) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratBold",
                ),
              ),
              SizedBox(height: 10),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Text(
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
