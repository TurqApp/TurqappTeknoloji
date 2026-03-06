import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';

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
    fetchFromFirestore();

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

  Future<void> fetchFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          familyInfo.value =
              userString(data, key: 'familyInfo', scope: 'family');
          fatherName.value.text =
              userString(data, key: 'fatherName', scope: 'family');
          fatherSurname.value.text =
              userString(data, key: 'fatherSurname', scope: 'family');
          fatherSalary.value.text =
              userString(data, key: 'fatherSalary', scope: 'family');
          fatherPhoneNumber.value.text =
              userString(data, key: 'fatherPhone', scope: 'family');
          fatherLiving.value = userString(
            data,
            key: 'fatherLiving',
            scope: 'family',
            fallback: "Seçiniz",
          );
          fatherJob.value = userString(
            data,
            key: 'fatherJob',
            scope: 'family',
            fallback: "Meslek Seç",
          );
          motherName.value.text =
              userString(data, key: 'motherName', scope: 'family');
          motherSurname.value.text =
              userString(data, key: 'motherSurname', scope: 'family');
          motherSalary.value.text =
              userString(data, key: 'motherSalary', scope: 'family');
          motherPhoneNumber.value.text =
              userString(data, key: 'motherPhone', scope: 'family');
          motherLiving.value = userString(
            data,
            key: 'motherLiving',
            scope: 'family',
            fallback: "Seçiniz",
          );
          motherJob.value = userString(
            data,
            key: 'motherJob',
            scope: 'family',
            fallback: "Meslek Seç",
          );
          totalLiving.value.text = userInt(
            data,
            key: 'totalLiving',
            scope: 'family',
          ).toString();
          if (totalLiving.value.text == '0') {
            totalLiving.value.clear();
          }
          evMulkiyeti.value = userString(
            data,
            key: 'evMulkiyeti',
            scope: 'family',
            fallback: "Seçim Yap",
          );
          city.value = userString(data, key: 'ikametSehir');
          town.value = userString(data, key: 'ikametIlce');
        } else {
          _resetToDefaults();
        }
      } else {
        _resetToDefaults();
      }
    } catch (e) {
      print('Error fetching family info: $e');
    }
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
        ...scopedUserUpdate(
          scope: 'family',
          values: {
            "familyInfo": familyInfo.value,
            "fatherName":
                fatherLiving.value == "Evet" ? fatherName.value.text : "",
            "fatherSurname":
                fatherLiving.value == "Evet" ? fatherSurname.value.text : "",
            "fatherJob": fatherLiving.value == "Evet" ? fatherJob.value : "",
            "fatherPhone": fatherLiving.value == "Evet"
                ? fatherPhoneNumber.value.text
                : "",
            "fatherLiving": fatherLiving.value,
            "fatherSalary":
                fatherLiving.value == "Evet" ? fatherSalary.value.text : "",
            "motherName":
                motherLiving.value == "Evet" ? motherName.value.text : "",
            "motherSurname":
                motherLiving.value == "Evet" ? motherSurname.value.text : "",
            "motherJob": motherLiving.value == "Evet" ? motherJob.value : "",
            "motherPhone": motherLiving.value == "Evet"
                ? motherPhoneNumber.value.text
                : "",
            "motherLiving": motherLiving.value,
            "motherSalary":
                motherLiving.value == "Evet" ? motherSalary.value.text : "",
            "totalLiving": int.tryParse(totalLiving.value.text) ?? 0,
            "evMulkiyeti": evMulkiyeti.value,
          },
        ),
        "ikametSehir": city.value,
        "ikametIlce": town.value,
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
        ...scopedUserUpdate(
          scope: 'family',
          values: {
            "familyInfo": "",
            "fatherName": "",
            "fatherSurname": "",
            "fatherJob": "",
            "fatherPhone": "",
            "fatherLiving": "Seçiniz",
            "fatherSalary": "",
            "motherName": "",
            "motherSurname": "",
            "motherJob": "",
            "motherPhone": "",
            "motherLiving": "Seçiniz",
            "motherSalary": "",
            "totalLiving": 0,
            "evMulkiyeti": "Seçim Yap",
          },
        ),
        "ikametSehir": "",
        "ikametIlce": "",
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
