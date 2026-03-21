import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

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
    });
  }

  void setData() {
    _opticalFormRepository
        .saveUserAnswers(
          model.docID,
          CurrentUserService.instance.userId,
          answers: cevaplar.toList(growable: false),
          ogrenciNo: ogrenciNo.text,
          fullName: fullName.text,
        )
        .then((_) => Get.back());
  }

  void kullaniciyiSinavGirdiKaydet() {
    _opticalFormRepository.initializeUserAnswers(
      model.docID,
      CurrentUserService.instance.userId,
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
        "answer_key.turn_on_internet_title".tr,
        "answer_key.turn_on_internet_body".tr,
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
    infoAlert(
      title: title,
      message: desc,
    );
  }
}
