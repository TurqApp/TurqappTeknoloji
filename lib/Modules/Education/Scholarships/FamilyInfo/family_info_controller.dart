import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';

class FamilyInfoController extends GetxController {
  static const String _selectValue = "Seçiniz";
  static const String _selectHomeOwnership = "Seçim Yap";
  static const String _selectJob = "Meslek Seç";
  static const String _yesValue = "Evet";
  final UserRepository _userRepository = UserRepository.ensure();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final isLoading = true.obs;
  final familyInfo = ''.obs;

  final fatherName = TextEditingController().obs;
  final fatherSurname = TextEditingController().obs;
  final fatherSalary = TextEditingController().obs;
  final fatherPhoneNumber = TextEditingController().obs;
  final fatherLiving = _selectValue.obs;
  final fatherJob = _selectJob.obs;
  final motherName = TextEditingController().obs;
  final motherSurname = TextEditingController().obs;
  final motherSalary = TextEditingController().obs;
  final motherPhoneNumber = TextEditingController().obs;
  final motherLiving = _selectValue.obs;
  final motherJob = _selectJob.obs;
  final totalLiving = TextEditingController().obs;
  final evMulkiyeti = _selectHomeOwnership.obs;
  final city = "".obs;
  final town = "".obs;
  final ScrollController scrollController = ScrollController();

  final evevMulkiyeti =
      ["Kendinize Ait Ev", "Yakınınıza Ait Ev", "Lojman", "Kira"].obs;
  final living = [_yesValue, "Hayır"].obs;
  final sehirler = <String>[].obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;

  bool get isFatherUnselected => fatherLiving.value == _selectValue;
  bool get isMotherUnselected => motherLiving.value == _selectValue;
  bool get isFatherAlive => fatherLiving.value == _yesValue;
  bool get isMotherAlive => motherLiving.value == _yesValue;
  bool get isHomeOwnershipUnselected =>
      evMulkiyeti.value == _selectHomeOwnership;

  String get defaultSelection => _selectValue;
  String get defaultHomeOwnershipSelection => _selectHomeOwnership;
  String get defaultJobSelection => _selectJob;

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
      if (value != _yesValue) {
        _clearFatherFields();
      }
    });

    ever(motherLiving, (value) {
      if (value != _yesValue) {
        _clearMotherFields();
      }
    });
  }

  String localizedSelection(String value) {
    switch (value) {
      case _yesValue:
        return 'common.yes'.tr;
      case 'Hayır':
        return 'common.no'.tr;
      case 'Kendinize Ait Ev':
        return 'family_info.home_owned'.tr;
      case 'Yakınınıza Ait Ev':
        return 'family_info.home_relative'.tr;
      case 'Lojman':
        return 'family_info.home_lodging'.tr;
      case 'Kira':
        return 'family_info.home_rent'.tr;
      default:
        return value;
    }
  }

  Future<void> loadSehirler() async {
    try {
      sehirlerVeIlcelerData.value =
          await _cityDirectoryService.getCitiesAndDistricts();
      sehirler.value = await _cityDirectoryService.getSortedCities();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFromFirestore() async {
    try {
      final data = await _userRepository.getUserRaw(
        FirebaseAuth.instance.currentUser!.uid,
      );
      if (data != null) {
        familyInfo.value = userString(data, key: 'familyInfo', scope: 'family');
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
        city.value = userString(data, key: 'ikametSehir', scope: 'profile');
        town.value = userString(data, key: 'ikametIlce', scope: 'profile');
      } else {
        _resetToDefaults();
      }
    } catch (_) {}
  }

  void _resetToDefaults() {
    fatherLiving.value = _selectValue;
    fatherJob.value = _selectJob;
    motherLiving.value = _selectValue;
    motherJob.value = _selectJob;
    evMulkiyeti.value = _selectHomeOwnership;
  }

  void _clearFatherFields() {
    fatherName.value.clear();
    fatherSurname.value.clear();
    fatherSalary.value.clear();
    fatherPhoneNumber.value.clear();
    fatherJob.value = _selectJob;
  }

  void _clearMotherFields() {
    motherName.value.clear();
    motherSurname.value.clear();
    motherSalary.value.clear();
    motherPhoneNumber.value.clear();
    motherJob.value = _selectJob;
  }

  void showIlSec() {
    Get.bottomSheet(
      ListBottomSheet(
        list: sehirler,
        title: 'common.select_city'.tr,
        startSelection: city.value,
        onBackData: (v) {
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
        title: 'common.select_district'.tr,
        startSelection: town.value,
        onBackData: (v) {
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
    final localizedList = list.map(localizedSelection).toList();
    final currentSelection = selectedValue.value.isEmpty
        ? ''
        : localizedSelection(selectedValue.value);
    Get.bottomSheet(
      AppBottomSheet(
        list: localizedList,
        title: title,
        startSelection: currentSelection,
        onBackData: (v) {
          final selectedIndex = localizedList.indexOf(v);
          selectedValue.value = selectedIndex >= 0 ? list[selectedIndex] : v;
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
    if (fatherLiving.value == _selectValue) {
      AppSnackbar(
        'common.warning'.tr,
        'family_info.select_father_alive'.tr,
      );
      return;
    }

    if (motherLiving.value == _selectValue) {
      AppSnackbar(
        'common.warning'.tr,
        'family_info.select_mother_alive'.tr,
      );
      return;
    }

    // Baba hayatta ise validasyon
    if (fatherLiving.value == _yesValue) {
      if (fatherName.value.text.isEmpty) {
        AppSnackbar('common.warning'.tr, 'scholarship.applicant.father_name'.tr);
        return;
      }
      if (fatherSurname.value.text.isEmpty) {
        AppSnackbar(
          'common.warning'.tr,
          'scholarship.applicant.father_surname'.tr,
        );
        return;
      }
      if (fatherJob.value == _selectJob) {
        AppSnackbar('common.warning'.tr, 'scholarship.applicant.father_job'.tr);
        return;
      }
      if (fatherSalary.value.text.isEmpty) {
        AppSnackbar(
          'common.warning'.tr,
          'family_info.father_salary_missing'.tr,
        );
        return;
      }
      if (fatherPhoneNumber.value.text.isEmpty) {
        AppSnackbar(
          'common.warning'.tr,
          'family_info.father_phone_missing'.tr,
        );
        return;
      }
      if (fatherPhoneNumber.value.text.length < 10) {
        AppSnackbar('common.error'.tr, 'family_info.father_phone_invalid'.tr);
        return;
      }
    }

    // Anne hayatta ise validasyon
    if (motherLiving.value == _yesValue) {
      if (motherName.value.text.isEmpty) {
        AppSnackbar('common.warning'.tr, 'scholarship.applicant.mother_name'.tr);
        return;
      }
      if (motherSurname.value.text.isEmpty) {
        AppSnackbar(
          'common.warning'.tr,
          'scholarship.applicant.mother_surname'.tr,
        );
        return;
      }
      if (motherJob.value == _selectJob) {
        AppSnackbar('common.warning'.tr, 'scholarship.applicant.mother_job'.tr);
        return;
      }
      if (motherSalary.value.text.isEmpty) {
        AppSnackbar(
          'common.warning'.tr,
          'family_info.mother_salary_missing'.tr,
        );
        return;
      }
      if (motherPhoneNumber.value.text.isEmpty) {
        AppSnackbar(
          'common.warning'.tr,
          'family_info.mother_phone_missing'.tr,
        );
        return;
      }
      if (motherPhoneNumber.value.text.length < 10) {
        AppSnackbar('common.error'.tr, 'family_info.mother_phone_invalid'.tr);
        return;
      }
    }

    // Genel validasyonlar
    if (totalLiving.value.text.isEmpty) {
      AppSnackbar('common.warning'.tr, 'family_info.family_size'.tr);
      return;
    }
    if (evMulkiyeti.value == _selectHomeOwnership) {
      AppSnackbar('common.warning'.tr, 'scholarship.applicant.home_ownership'.tr);
      return;
    }
    if (city.value.isEmpty) {
      AppSnackbar(
        'common.warning'.tr,
        'scholarship.applicant.residence_city'.tr,
      );
      return;
    }
    if (town.value.isEmpty) {
      AppSnackbar(
        'common.warning'.tr,
        'scholarship.applicant.residence_district'.tr,
      );
      return;
    }

    // Veri kaydetme
    try {
      await _userRepository.updateUserFields(
        FirebaseAuth.instance.currentUser!.uid,
        {
          ...scopedUserUpdate(
            scope: 'family',
            values: {
              "familyInfo": familyInfo.value,
              "fatherName":
                  fatherLiving.value == _yesValue ? fatherName.value.text : "",
              "fatherSurname":
                  fatherLiving.value == _yesValue ? fatherSurname.value.text : "",
              "fatherJob": fatherLiving.value == _yesValue ? fatherJob.value : "",
              "fatherPhone": fatherLiving.value == _yesValue
                  ? fatherPhoneNumber.value.text
                  : "",
              "fatherLiving": fatherLiving.value,
              "fatherSalary":
                  fatherLiving.value == _yesValue ? fatherSalary.value.text : "",
              "motherName":
                  motherLiving.value == _yesValue ? motherName.value.text : "",
              "motherSurname":
                  motherLiving.value == _yesValue ? motherSurname.value.text : "",
              "motherJob": motherLiving.value == _yesValue ? motherJob.value : "",
              "motherPhone": motherLiving.value == _yesValue
                  ? motherPhoneNumber.value.text
                  : "",
              "motherLiving": motherLiving.value,
              "motherSalary":
                  motherLiving.value == _yesValue ? motherSalary.value.text : "",
              "totalLiving": int.tryParse(totalLiving.value.text) ?? 0,
              "evMulkiyeti": evMulkiyeti.value,
            },
          ),
          ...scopedUserUpdate(
            scope: 'profile',
            values: {
              "ikametSehir": city.value,
              "ikametIlce": town.value,
            },
          ),
        },
      );

      Get.back();
      AppSnackbar('common.success'.tr, 'family_info.saved'.tr);
    } catch (e) {
      AppSnackbar('common.error'.tr, 'family_info.save_failed'.tr);
    }
  }
  // FamilyInfoController.dart içine bu fonksiyonu ekleyin:

  void resetFamilyInfo() async {
    try {
      // Firestore'dan aile bilgilerini sıfırla
      await _userRepository.updateUserFields(
        FirebaseAuth.instance.currentUser!.uid,
        {
          ...scopedUserUpdate(
            scope: 'family',
            values: {
              "familyInfo": "",
              "fatherName": "",
              "fatherSurname": "",
              "fatherJob": "",
              "fatherPhone": "",
              "fatherLiving": _selectValue,
              "fatherSalary": "",
              "motherName": "",
              "motherSurname": "",
              "motherJob": "",
              "motherPhone": "",
              "motherLiving": _selectValue,
              "motherSalary": "",
              "totalLiving": 0,
              "evMulkiyeti": _selectHomeOwnership,
            },
          ),
          ...scopedUserUpdate(
            scope: 'profile',
            values: {
              "ikametSehir": "",
              "ikametIlce": "",
            },
          ),
        },
      );

      // UI'yi hemen güncelle
      familyInfo.value = "";
      fatherName.value.clear();
      fatherSurname.value.clear();
      fatherSalary.value.clear();
      fatherPhoneNumber.value.clear();
      fatherLiving.value = _selectValue;
      fatherJob.value = _selectJob;
      motherName.value.clear();
      motherSurname.value.clear();
      motherSalary.value.clear();
      motherPhoneNumber.value.clear();
      motherLiving.value = _selectValue;
      motherJob.value = _selectJob;
      totalLiving.value.clear();
      evMulkiyeti.value = _selectHomeOwnership;
      city.value = "";
      town.value = "";

      Navigator.of(Get.context!).pop();
      AppSnackbar('common.success'.tr, 'family_info.reset_success'.tr);
    } catch (e) {
      AppSnackbar('common.error'.tr, 'family_info.reset_failed'.tr);
    }
  }
}
