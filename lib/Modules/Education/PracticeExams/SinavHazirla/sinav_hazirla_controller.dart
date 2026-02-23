import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import 'package:path/path.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavSorusuHazirla/sinav_sorusu_hazirla.dart';

class SinavHazirlaController extends GetxController {
  var sinavIsmi = TextEditingController().obs;
  var aciklama = TextEditingController().obs;
  var startDate = DateTime.now().obs;
  var selectedTime = TimeOfDay(hour: 15, minute: 00).obs;
  var sinavTuru = 'TYT'.obs;
  var currentDersler = <String>[].obs;
  var kpssSecilenLisans = 'Ortaöğretim'.obs;
  var yanlisDogruyuGotururMu = false.obs;
  var public = true.obs;
  var sure = 140.obs;
  var showCalendar = false.obs;
  var showSureler = false.obs;
  var cover = Rx<File?>(null);
  var isLoadingImage = false.obs;
  var isSaving = false.obs;
  var soruSayisiTextFields = <TextEditingController>[].obs;
  var docID = DateTime.now().millisecondsSinceEpoch.toString().obs;

  SinavModel? sinavModel;

  SinavHazirlaController({this.sinavModel});

  @override
  void onInit() {
    super.onInit();
    if (sinavModel != null) {
      sinavTuru.value = sinavModel!.sinavTuru;
      sinavIsmi.value.text = sinavModel!.sinavAdi;
      aciklama.value.text = sinavModel!.sinavAciklama;
      kpssSecilenLisans.value = sinavModel!.kpssSecilenLisans;
      yanlisDogruyuGotururMu.value = true;
      currentDersler.assignAll(sinavModel!.dersler);
      docID.value = sinavModel!.docID;
      public.value = sinavModel!.public;
      sure.value = sinavModel!.bitisDk.toInt();
      soruSayisiTextFields.assignAll(
        sinavModel!.soruSayilari
            .map((soru) => TextEditingController(text: soru))
            .toList(),
      );
    } else {
      currentDersler.assignAll(tytDersler);
      soruSayisiTextFields.assignAll(
        List.generate(
          tytDersler.length,
          (index) => TextEditingController(text: ''),
        ),
      );
    }
  }

  @override
  void onClose() {
    sinavIsmi.value.dispose();
    aciklama.value.dispose();
    for (var controller in soruSayisiTextFields) {
      controller.dispose();
    }
    super.onClose();
  }

  Future<void> pickImageFromGallery() async {
    isLoadingImage.value = true;
    try {
      final ctx = Get.context;
      if (ctx == null) return;
      final pickedFile = await AppImagePickerService.pickSingleImage(ctx);
      if (pickedFile != null) {
        cover.value = pickedFile;
        await _analyzeImage();
      }
    } catch (e) {
      AppSnackbar("Hata", "Resim seçilemedi.");
    } finally {
      isLoadingImage.value = false;
    }
  }

  Future<void> _analyzeImage() async {
    if (cover.value == null) return;
    try {
      NsfwDetector detector = await NsfwDetector.load(threshold: 0.3);
      NsfwResult? result = await detector.detectNSFWFromFile(cover.value!);
      if (result?.isNsfw ?? false) {
        AppSnackbar("Hata", "Seçilen resim uygun değil!");
        cover.value = null;
      }
    } catch (e) {
      AppSnackbar("Hata", "Resim analizi yapılamadı.");
    }
  }

  Future<void> selectTime(BuildContext context) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: selectedTime.value,
    );
    if (time != null) {
      selectedTime.value = time;
    }
  }

  Future<void> uploadImage(File imageFile, String docID) async {
    try {
      String fileName = basename(imageFile.path);
      Reference firebaseStorageRef = FirebaseStorage.instance.ref().child(
            'DenemeSinavlari/$docID/$fileName',
          );
      UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      await FirebaseFirestore.instance.collection("Sinavlar").doc(docID).update(
        {"cover": downloadUrl},
      );
    } catch (e) {
      AppSnackbar("Hata", "Resim yüklenemedi.");
    }
  }

  void setData(BuildContext context) async {
    isSaving.value = true;
    try {
      DateTime combinedDateTime = DateTime(
        startDate.value.year,
        startDate.value.month,
        startDate.value.day,
        selectedTime.value.hour,
        selectedTime.value.minute,
      );

      await FirebaseFirestore.instance
          .collection("Sinavlar")
          .doc(docID.value)
          .set({
        "sinavAdi": sinavIsmi.value.text,
        "sinavAciklama": aciklama.value.text,
        "timeStamp": combinedDateTime.millisecondsSinceEpoch,
        "dersler": currentDersler,
        "sinavTuru": sinavTuru.value,
        "kpssSecilenLisans": sinavTuru.value == "KPSS"
            ? kpssSecilenLisans.value
            : sinavTuru.value,
        "soruSayilari":
            soruSayisiTextFields.map((controller) => controller.text).toList(),
        "taslak": true,
        "public": public.value,
        "userID": FirebaseAuth.instance.currentUser!.uid,
        "bitisDk": sure.value,
        "bitis": combinedDateTime.millisecondsSinceEpoch + (sure.value * 60000),
      }, SetOptions(merge: true));

      if (cover.value != null) {
        await uploadImage(cover.value!, docID.value);
      }

      Get.to(
        () => SinavSorusuHazirla(
          docID: docID.value,
          sinavTuru: sinavTuru.value,
          tumDersler: currentDersler.toList(),
          derslerinSoruSayilari: soruSayisiTextFields
              .map((controller) => controller.text)
              .toList(),
          complated: () => Get.back(),
        ),
      );
    } catch (e) {
      AppSnackbar("Hata", "Sınav kaydedilemedi.");
    } finally {
      isSaving.value = false;
    }
  }

  void updateSinavTuru(String newTuru) {
    sinavTuru.value = newTuru;
    for (var controller in soruSayisiTextFields) {
      controller.dispose();
    }
    if (newTuru == "LGS") {
      currentDersler.assignAll(lgsDersler);
    } else if (newTuru == "TYT") {
      currentDersler.assignAll(tytDersler);
    } else if (newTuru == "AYT") {
      currentDersler.assignAll(aytDersler);
    } else if (newTuru == "KPSS") {
      kpssSecilenLisans.value = "Ortaöğretim";
      currentDersler.assignAll(kpssDerslerOrtaVeOnLisans);
    } else if (newTuru == "ALES" || newTuru == "DGS") {
      currentDersler.assignAll(alesVeDgsDersler);
    } else {
      currentDersler.assignAll(ydsDersler);
    }
    soruSayisiTextFields.assignAll(
      List.generate(currentDersler.length, (index) => TextEditingController()),
    );
  }

  void updateKpssLisans(String newLisans) {
    kpssSecilenLisans.value = newLisans;
    for (var controller in soruSayisiTextFields) {
      controller.dispose();
    }
    if (newLisans == "Ortaöğretim" ||
        newLisans == "Lisans" ||
        newLisans == "Ön Lisans") {
      currentDersler.assignAll(kpssDerslerOrtaVeOnLisans);
    } else if (newLisans == "Eğitim Birimleri") {
      currentDersler.assignAll(kpssDerslerEgitimbirimleri);
    } else if (newLisans == "A Grubu 1") {
      currentDersler.assignAll(kpssDerslerAgrubu1);
    } else if (newLisans == "A Grubu 2") {
      currentDersler.assignAll(kpssDerslerAgrubu2);
    }
    soruSayisiTextFields.assignAll(
      List.generate(
        currentDersler.length,
        (index) => TextEditingController(text: "1"),
      ),
    );
  }

  Future<void> resetForm() async {
    sinavIsmi.value.clear();
    aciklama.value.clear();
    cover.value = null;
    startDate.value = DateTime.now();
    selectedTime.value = TimeOfDay(hour: 15, minute: 00);
    sinavTuru.value = 'TYT';
    currentDersler.assignAll(tytDersler);
    for (var controller in soruSayisiTextFields) {
      controller.dispose();
    }
    soruSayisiTextFields.assignAll(
      List.generate(
        tytDersler.length,
        (index) => TextEditingController(text: ''),
      ),
    );
    public.value = true;
    sure.value = 140;
    docID.value = DateTime.now().millisecondsSinceEpoch.toString();
  }
}
