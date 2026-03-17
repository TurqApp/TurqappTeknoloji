import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/education_reference_data_service.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Models/Education/dormitory_model.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';

class DormitoryInfoController extends GetxController {
  final UserRepository _userRepository = UserRepository.ensure();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final EducationReferenceDataService _referenceDataService =
      EducationReferenceDataService.ensure();
  final isLoading = true.obs;
  final sehir = "Şehir Seç".obs;
  final ilce = "İlçe Seç".obs;
  final yurt = "".obs;
  final sub = "İdari Seç".obs;
  final listedeYok = false.obs;
  final yurtInput = TextEditingController();
  final yurtSelectionController = TextEditingController();
  final yurtInputText = "".obs;
  final subList = ["DEVLET", "ÖZEL"].obs;
  final sehirler = <String>[].obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
  final yurtList = <DormitoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSehirler();
    fetchYurtData();
    fetchFirestoreData();
    ever(yurt, (_) {
      yurtSelectionController.text = yurt.value;
    });
    yurtInput.addListener(() {
      yurtInputText.value = yurtInput.text;
    });
  }

  @override
  void onClose() {
    yurtInput.dispose();
    yurtSelectionController.dispose();
    super.onClose();
  }

  Future<void> loadSehirler() async {
    try {
      sehirlerVeIlcelerData.value =
          await _cityDirectoryService.getCitiesAndDistricts();
      sehirler.value = await _cityDirectoryService.getSortedCities();
    } catch (_) {}
  }

  Future<void> fetchYurtData() async {
    try {
      yurtList.value = await _referenceDataService.getDormitories();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFirestoreData() async {
    try {
      final data = await _userRepository.getUserRaw(
        FirebaseAuth.instance.currentUser!.uid,
      );
      if (data != null) {
        yurt.value = userString(
          data,
          key: "yurt",
          scope: "family",
        );
      }
    } catch (_) {}
  }

  void showIdariSec() {
    Get.bottomSheet(
      AppBottomSheet(
        list: subList,
        title: "İdari Seç",
        startSelection: sub.value,
        onBackData: (v) {
          sub.value = v;
          yurt.value = "";
          yurtSelectionController.clear();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  void showIlSec() {
    Get.bottomSheet(
      ListBottomSheet(
        list: sehirler,
        title: "Şehir Seç",
        startSelection: sehir.value,
        onBackData: (v) {
          sehir.value = v;
          ilce.value = "";
          yurt.value = "";
          yurtSelectionController.clear();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  void showYurtSec() {
    final filteredYurtList = yurtList
        .where(
          (item) =>
              item.sub == sub.value.toUpperCase() &&
              item.ilAdi == sehir.value.toUpperCase(),
        )
        .map((item) => item.adi)
        .toList();

    if (filteredYurtList.isEmpty) {
      AppSnackbar("Bilgi", "Bu şehir ve idari tür için yurt bulunamadı");
      return;
    }

    Get.bottomSheet(
      ListBottomSheet(
        list: filteredYurtList,
        title: "Yurt Seç",
        startSelection: yurt.value.isEmpty ? null : yurt.value,
        onBackData: (v) {
          yurt.value = v;
          listedeYok.value = false;
          yurtInput.clear();
          yurtInputText.value = "";
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  void toggleListedeYok() {
    listedeYok.value = !listedeYok.value;
    if (listedeYok.value) {
      yurt.value = "";
      yurtSelectionController.clear();
    } else {
      yurtInput.clear();
      yurtInputText.value = "";
    }
  }

  void selectYurt(DormitoryModel item) {
    yurt.value = item.adi;
    sehir.value = "Şehir Seç";
    sub.value = "İdari Seç";
    listedeYok.value = false;
    yurtInput.clear();
    yurtInputText.value = "";
    yurtSelectionController.text = item.adi;
  }

  void saveData() async {
    if ((listedeYok.value && yurtInputText.value.isNotEmpty) ||
        (!listedeYok.value && yurt.value.isNotEmpty)) {
      try {
        final String savedYurt =
            listedeYok.value ? yurtInputText.value : yurt.value;
        await _userRepository.updateUserFields(
          FirebaseAuth.instance.currentUser!.uid,
          scopedUserUpdate(
            scope: 'family',
            values: {"yurt": savedYurt},
          ),
        );
        yurt.value = savedYurt;
        Get.back();
        AppSnackbar("Başarılı", "Yurt Bilgileriniz Kaydedildi.");
      } catch (_) {
        AppSnackbar("Hata", "Veri kaydedilemedi.");
      }
    } else {
      AppSnackbar("Hata", "Lütfen bir yurt seçin veya yurt adı girin");
    }
  }

  String capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : s;
}
