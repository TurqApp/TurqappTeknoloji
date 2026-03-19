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
  static const String _selectCity = "Şehir Seç";
  static const String _selectDistrict = "İlçe Seç";
  static const String _selectAdminType = "İdari Seç";
  String get selectCityValue => _selectCity;
  String get selectDistrictValue => _selectDistrict;
  String get selectAdminTypeValue => _selectAdminType;
  final UserRepository _userRepository = UserRepository.ensure();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final EducationReferenceDataService _referenceDataService =
      EducationReferenceDataService.ensure();
  final isLoading = true.obs;
  final sehir = _selectCity.obs;
  final ilce = _selectDistrict.obs;
  final yurt = "".obs;
  final sub = _selectAdminType.obs;
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

  String localizedAdminType(String value) {
    switch (value) {
      case "DEVLET":
        return 'dormitory.admin_public'.tr;
      case "ÖZEL":
        return 'dormitory.admin_private'.tr;
      case _selectAdminType:
        return 'dormitory.select_admin_type'.tr;
      default:
        return value;
    }
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
        list: subList.map(localizedAdminType).toList(),
        title: 'dormitory.select_admin_type'.tr,
        startSelection: localizedAdminType(sub.value),
        onBackData: (v) {
          final localizedList = subList.map(localizedAdminType).toList();
          final selectedIndex = localizedList.indexOf(v);
          sub.value = selectedIndex >= 0 ? subList[selectedIndex] : v;
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
        title: 'common.select_city'.tr,
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
      AppSnackbar('common.warning'.tr, 'dormitory.not_found_for_filters'.tr);
      return;
    }

    Get.bottomSheet(
      ListBottomSheet(
        list: filteredYurtList,
        title: 'dormitory.select_dormitory'.tr,
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
    sehir.value = _selectCity;
    sub.value = _selectAdminType;
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
        AppSnackbar('common.success'.tr, 'dormitory.saved'.tr);
      } catch (_) {
        AppSnackbar('common.error'.tr, 'dormitory.save_failed'.tr);
      }
    } else {
      AppSnackbar('common.error'.tr, 'dormitory.select_or_enter'.tr);
    }
  }

  String capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : s;
}
