import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:turqappv2/Core/BottomSheets/AppBottomSheet.dart';
import 'package:turqappv2/Models/CitiesModel.dart';
import 'package:turqappv2/Core/BottomSheets/ListBottomSheet.dart';

class FamilyInfoController extends GetxController {
  final isLoading = true.obs;
  final familyInfo = ''.obs;

  final fatherName = TextEditingController().obs;
  final fatherSurname = TextEditingController().obs;
  final fatherSalary = TextEditingController().obs;
  final fatherPhoneNumber = TextEditingController().obs;
  final fatherLiving = "Seçiniz".obs;
  final fatherJob = "Meslek Seç".obs;
  final motherName = TextEditingController().obs;
  final motherSurname = TextEditingController().obs;
  final motherSalary = TextEditingController().obs;
  final motherPhoneNumber = TextEditingController().obs;
  final motherLiving = "Seçiniz".obs;
  final motherJob = "Meslek Seç".obs;
  final totalLiving = TextEditingController().obs;
  final evMulkiyeti = "Seçim Yap".obs;
  final city = "".obs;
  final town = "".obs;
  final ScrollController scrollController = ScrollController();

  final evevMulkiyeti =
      ["Kendinize Ait Ev", "Yakınınıza Ait Ev", "Lojman", "Kira"].obs;
  final living = ["Evet", "Hayır"].obs;
  final sehirler = <String>[].obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(() {
      FocusScope.of(Get.context!).unfocus();
    });
    loadSehirler();
    listenToFirestore();

    // Hayatta mı sorusu değiştiğinde ilgili alanları temizle
    ever(fatherLiving, (value) {
      if (value != "Evet") {
        _clearFatherFields();
      }
    });

    ever(motherLiving, (value) {
      if (value != "Evet") {
        _clearMotherFields();
      }
    });
  }

  Future<void> loadSehirler() async {
    try {
      final String response = await DefaultAssetBundle.of(
        Get.context!,
      ).loadString('assets/data/CityDistrict.json');
      final List<dynamic> data = json.decode(response);
      sehirlerVeIlcelerData.value =
          data.map((json) => CitiesModel.fromJson(json)).toList();
      sehirler.value =
          sehirlerVeIlcelerData.map((item) => item.il).toSet().toList();
    } catch (e) {
      print("Error loading cities: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void listenToFirestore() {
    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .listen((DocumentSnapshot doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          familyInfo.value = data['familyInfo'] ?? '';
          fatherName.value.text = data['fatherName'] ?? '';
          fatherSurname.value.text = data['fatherSurname'] ?? '';
          fatherSalary.value.text = data['fatherSalary'] ?? '';
          fatherPhoneNumber.value.text = data['fatherPhone'] ?? '';
          fatherLiving.value = data['fatherLiving'] ?? "Seçiniz";
          fatherJob.value = data['fatherJob'] ?? "Meslek Seç";
          motherName.value.text = data['motherName'] ?? '';
          motherSurname.value.text = data['motherSurname'] ?? '';
          motherSalary.value.text = data['motherSalary'] ?? '';
          motherPhoneNumber.value.text = data['motherPhone'] ?? '';
          motherLiving.value = data['motherLiving'] ?? "Seçiniz";
          motherJob.value = data['motherJob'] ?? "Meslek Seç";
          totalLiving.value.text = data['totalLiving']?.toString() ?? '';
          evMulkiyeti.value = data['evMulkiyeti'] ?? "Seçim Yap"; // Fixed typo
          city.value = data['ikametSehir'] ?? '';
          town.value = data['ikametIlce'] ?? '';
        } else {
          _resetToDefaults();
        }
      } else {
        _resetToDefaults();
      }
    });
  }

  void _resetToDefaults() {
    fatherLiving.value = "Seçiniz";
    fatherJob.value = "Meslek Seç";
    motherLiving.value = "Seçiniz";
    motherJob.value = "Meslek Seç";
    evMulkiyeti.value = "Seçim Yap";
  }

  void _clearFatherFields() {
    fatherName.value.clear();
    fatherSurname.value.clear();
    fatherSalary.value.clear();
    fatherPhoneNumber.value.clear();
    fatherJob.value = "Meslek Seç";
  }

  void _clearMotherFields() {
    motherName.value.clear();
    motherSurname.value.clear();
    motherSalary.value.clear();
    motherPhoneNumber.value.clear();
    motherJob.value = "Meslek Seç";
  }

  void showIlSec() {
    Get.bottomSheet(
      ListBottomSheet(
        list: sehirler,
        title: "Şehir Seç",
        startSelection: city.value,
        onBackData: (v) {
          print("SELECTED $v");
          city.value = v;
          town.value = "";
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  void showIlcelerSec() {
    final List<String> ilceListesi = sehirlerVeIlcelerData
        .where((doc) => doc.il == city.value && city.value != "")
        .map((doc) => doc.ilce)
        .toList();

    Get.bottomSheet(
      ListBottomSheet(
        list: ilceListesi,
        title: "İlçe Seç",
        startSelection: town.value,
        onBackData: (v) {
          print("SELECTED $v");
          town.value = v;
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  void showBottomSheet(
    String title,
    RxString selectedValue,
    List<String> list,
  ) {
    Get.bottomSheet(
      ListBottomSheet(
        list: list,
        title: title,
        startSelection: selectedValue.value,
        onBackData: (v) {
          print("SELECTED $v");
          selectedValue.value = v;
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  void showBottomSheet2(
    String title,
    RxString selectedValue,
    List<String> list,
  ) {
    Get.bottomSheet(
      AppBottomSheet(
        list: list,
        title: title,
        startSelection: selectedValue.value,
        onBackData: (v) {
          log("SELECTED $v");
          selectedValue.value = v;
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  void setData() async {
    // Temel validasyonlar
    if (fatherLiving.value == "Seçiniz") {
      AppSnackbar("Eksik alan!", "Baba hayatta mı? seçimini yapınız");
      return;
    }

    if (motherLiving.value == "Seçiniz") {
      AppSnackbar("Eksik alan!", "Anne hayatta mı? seçimini yapınız");
      return;
    }

    // Baba hayatta ise validasyon
    if (fatherLiving.value == "Evet") {
      if (fatherName.value.text.isEmpty) {
        AppSnackbar("Eksik alan!", "Baba Adı");
        return;
      }
      if (fatherSurname.value.text.isEmpty) {
        AppSnackbar("Eksik alan!", "Baba Soyadı");
        return;
      }
      if (fatherJob.value == "Meslek Seç") {
        AppSnackbar("Eksik alan!", "Baba mesleği");
        return;
      }
      if (fatherSalary.value.text.isEmpty) {
        AppSnackbar("Eksik alan!", "Baba maaş bilgisi");
        return;
      }
      if (fatherPhoneNumber.value.text.isEmpty) {
        AppSnackbar("Eksik alan!", "Baba telefon numarası");
        return;
      }
      if (fatherPhoneNumber.value.text.length < 10) {
        AppSnackbar(
            "Hatalı alan!", "Baba telefon numarası 10 haneli olmalıdır");
        return;
      }
    }

    // Anne hayatta ise validasyon
    if (motherLiving.value == "Evet") {
      if (motherName.value.text.isEmpty) {
        AppSnackbar("Eksik alan!", "Anne Adı");
        return;
      }
      if (motherSurname.value.text.isEmpty) {
        AppSnackbar("Eksik alan!", "Anne Soyadı");
        return;
      }
      if (motherJob.value == "Meslek Seç") {
        AppSnackbar("Eksik alan!", "Anne Mesleği");
        return;
      }
      if (motherSalary.value.text.isEmpty) {
        AppSnackbar("Eksik alan!", "Anne maaş bilgisi");
        return;
      }
      if (motherPhoneNumber.value.text.isEmpty) {
        AppSnackbar("Eksik alan!", "Anne telefon numarası");
        return;
      }
      if (motherPhoneNumber.value.text.length < 10) {
        AppSnackbar(
            "Hatalı alan!", "Anne telefon numarası 10 haneli olmalıdır");
        return;
      }
    }

    // Genel validasyonlar
    if (totalLiving.value.text.isEmpty) {
      AppSnackbar("Eksik alan!", "Ailede Yaşayan Sayısı");
      return;
    }
    if (evMulkiyeti.value == "Seçim Yap") {
      AppSnackbar("Eksik alan!", "Ev Mülkiyeti");
      return;
    }
    if (city.value.isEmpty) {
      AppSnackbar("Eksik alan!", "İkametgâh Şehiri");
      return;
    }
    if (town.value.isEmpty) {
      AppSnackbar("Eksik alan!", "İkametgâh İlçesi");
      return;
    }

    // Veri kaydetme
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        "familyInfo": familyInfo.value,
        // Baba bilgileri - sadece hayatta ise kaydet
        "fatherName": fatherLiving.value == "Evet" ? fatherName.value.text : "",
        "fatherSurname":
            fatherLiving.value == "Evet" ? fatherSurname.value.text : "",
        "fatherJob": fatherLiving.value == "Evet" ? fatherJob.value : "",
        "fatherPhone":
            fatherLiving.value == "Evet" ? fatherPhoneNumber.value.text : "",
        "fatherLiving": fatherLiving.value,
        "fatherSalary":
            fatherLiving.value == "Evet" ? fatherSalary.value.text : "",
        // Anne bilgileri - sadece hayatta ise kaydet
        "motherName": motherLiving.value == "Evet" ? motherName.value.text : "",
        "motherSurname":
            motherLiving.value == "Evet" ? motherSurname.value.text : "",
        "motherJob": motherLiving.value == "Evet" ? motherJob.value : "",
        "motherPhone":
            motherLiving.value == "Evet" ? motherPhoneNumber.value.text : "",
        "motherLiving": motherLiving.value,
        "motherSalary":
            motherLiving.value == "Evet" ? motherSalary.value.text : "",
        // Genel bilgiler
        "totalLiving": int.parse(totalLiving.value.text),
        "ikametSehir": city.value,
        "ikametIlce": town.value,
        "evMulkiyeti": evMulkiyeti.value,
      });

      Get.back();
      AppSnackbar("Başarılı", "Aile Bilgileriniz Kaydedildi.");
    } catch (e) {
      AppSnackbar("Hata!", "Bilgiler kaydedilemedi. Lütfen tekrar deneyin.");
    }
  }
  // FamilyInfoController.dart içine bu fonksiyonu ekleyin:

  void resetFamilyInfo() async {
    try {
      // Firestore'dan aile bilgilerini sıfırla
      await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        "familyInfo": "",
        // Baba bilgileri
        "fatherName": "",
        "fatherSurname": "",
        "fatherJob": "",
        "fatherPhone": "",
        "fatherLiving": "Seçiniz",
        "fatherSalary": "",
        // Anne bilgileri
        "motherName": "",
        "motherSurname": "",
        "motherJob": "",
        "motherPhone": "",
        "motherLiving": "Seçiniz",
        "motherSalary": "",
        // Genel bilgiler
        "totalLiving": "",
        "ikametSehir": "",
        "ikametIlce": "",
        "evMulkiyeti": "Seçim Yap",
      });

      // UI'yi hemen güncelle
      familyInfo.value = "";
      fatherName.value.clear();
      fatherSurname.value.clear();
      fatherSalary.value.clear();
      fatherPhoneNumber.value.clear();
      fatherLiving.value = "Seçiniz";
      fatherJob.value = "Meslek Seç";
      motherName.value.clear();
      motherSurname.value.clear();
      motherSalary.value.clear();
      motherPhoneNumber.value.clear();
      motherLiving.value = "Seçiniz";
      motherJob.value = "Meslek Seç";
      totalLiving.value.clear();
      evMulkiyeti.value = "Seçim Yap";
      city.value = "";
      town.value = "";

      Navigator.of(Get.context!).pop();
      AppSnackbar("Başarılı", "Aile Bilgileri Sıfırlandı.");
    } catch (e) {
      AppSnackbar("Hata!", "Bilgiler sıfırlanamadı. Lütfen tekrar deneyin.");
    }
  }
}
