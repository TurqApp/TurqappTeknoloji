import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class FamilyInfoController extends GetxController {
  static FamilyInfoController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(FamilyInfoController(), tag: tag, permanent: permanent);
  }

  static FamilyInfoController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<FamilyInfoController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<FamilyInfoController>(tag: tag);
  }

  static const String _selectValue = "Seçiniz";
  static const String _selectHomeOwnership = "Seçim Yap";
  static const String _selectJob = "Meslek Seç";
  static const String _yesValue = "Evet";
  static const String _noValue = "Hayır";
  static const String _ownedHome = "Kendinize Ait Ev";
  static const String _relativeHome = "Yakınınıza Ait Ev";
  static const String _lodgingHome = "Lojman";
  static const String _rentHome = "Kira";
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
      [_ownedHome, _relativeHome, _lodgingHome, _rentHome].obs;
  final living = [_yesValue, _noValue].obs;
  final sehirler = <String>[].obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;

  bool _matchesValue(String value, Set<String> variants) =>
      variants.contains(value.trim());

  bool _isSelectValue(String value) => _matchesValue(value, const <String>{
        _selectValue,
        'Select',
        'Auswählen',
        'Sélectionner',
        'Seleziona',
        'Выбрать',
      });
  bool _isSelectJobValue(String value) => _matchesValue(value, const <String>{
        _selectJob,
        'Select Job',
        'Beruf wählen',
        'Choisir une profession',
        'Seleziona professione',
        'Выберите профессию',
      });
  bool _isSelectHomeOwnershipValue(String value) =>
      _matchesValue(value, const <String>{
        _selectHomeOwnership,
        'Select',
        'Auswählen',
        'Sélectionner',
        'Seleziona',
        'Выбрать',
      });
  bool _isYesValue(String value) => _matchesValue(value, const <String>{
        _yesValue,
        'Yes',
        'Ja',
        'Oui',
        'Sì',
        'Si',
        'Да',
      });

  bool get isFatherUnselected => _isSelectValue(fatherLiving.value);
  bool get isMotherUnselected => _isSelectValue(motherLiving.value);
  bool get isFatherAlive => _isYesValue(fatherLiving.value);
  bool get isMotherAlive => _isYesValue(motherLiving.value);
  bool get isHomeOwnershipUnselected =>
      _isSelectHomeOwnershipValue(evMulkiyeti.value);

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
      if (!_isYesValue(value)) {
        _clearFatherFields();
      }
    });

    ever(motherLiving, (value) {
      if (!_isYesValue(value)) {
        _clearMotherFields();
      }
    });
  }

  String localizedSelection(String value) {
    switch (value) {
      case _selectValue:
      case _selectHomeOwnership:
        return 'common.select'.tr;
      case _selectJob:
        return 'family_info.select_job'.tr;
      case _yesValue:
        return 'common.yes'.tr;
      case _noValue:
        return 'common.no'.tr;
      case _ownedHome:
        return 'family_info.home_owned'.tr;
      case _relativeHome:
        return 'family_info.home_relative'.tr;
      case _lodgingHome:
        return 'family_info.home_lodging'.tr;
      case _rentHome:
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
        CurrentUserService.instance.userId,
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
          fallback: _selectValue,
        );
        fatherJob.value = userString(
          data,
          key: 'fatherJob',
          scope: 'family',
          fallback: _selectJob,
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
          fallback: _selectValue,
        );
        motherJob.value = userString(
          data,
          key: 'motherJob',
          scope: 'family',
          fallback: _selectJob,
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
          fallback: _selectHomeOwnership,
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
        itemLabelBuilder: (item) => localizedSelection(item.toString()),
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
    if (_isSelectValue(fatherLiving.value)) {
      AppSnackbar(
        'common.warning'.tr,
        'family_info.select_father_alive'.tr,
      );
      return;
    }

    if (_isSelectValue(motherLiving.value)) {
      AppSnackbar(
        'common.warning'.tr,
        'family_info.select_mother_alive'.tr,
      );
      return;
    }

    // Baba hayatta ise validasyon
    if (_isYesValue(fatherLiving.value)) {
      if (fatherName.value.text.isEmpty) {
        AppSnackbar(
            'common.warning'.tr, 'scholarship.applicant.father_name'.tr);
        return;
      }
      if (fatherSurname.value.text.isEmpty) {
        AppSnackbar(
          'common.warning'.tr,
          'scholarship.applicant.father_surname'.tr,
        );
        return;
      }
      if (_isSelectJobValue(fatherJob.value)) {
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
    if (_isYesValue(motherLiving.value)) {
      if (motherName.value.text.isEmpty) {
        AppSnackbar(
            'common.warning'.tr, 'scholarship.applicant.mother_name'.tr);
        return;
      }
      if (motherSurname.value.text.isEmpty) {
        AppSnackbar(
          'common.warning'.tr,
          'scholarship.applicant.mother_surname'.tr,
        );
        return;
      }
      if (_isSelectJobValue(motherJob.value)) {
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
    if (_isSelectHomeOwnershipValue(evMulkiyeti.value)) {
      AppSnackbar(
          'common.warning'.tr, 'scholarship.applicant.home_ownership'.tr);
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
        CurrentUserService.instance.userId,
        {
          ...scopedUserUpdate(
            scope: 'family',
            values: {
              "familyInfo": familyInfo.value,
              "fatherName":
                  _isYesValue(fatherLiving.value) ? fatherName.value.text : "",
              "fatherSurname": _isYesValue(fatherLiving.value)
                  ? fatherSurname.value.text
                  : "",
              "fatherJob":
                  _isYesValue(fatherLiving.value) ? fatherJob.value : "",
              "fatherPhone": _isYesValue(fatherLiving.value)
                  ? fatherPhoneNumber.value.text
                  : "",
              "fatherLiving": fatherLiving.value,
              "fatherSalary": _isYesValue(fatherLiving.value)
                  ? fatherSalary.value.text
                  : "",
              "motherName":
                  _isYesValue(motherLiving.value) ? motherName.value.text : "",
              "motherSurname": _isYesValue(motherLiving.value)
                  ? motherSurname.value.text
                  : "",
              "motherJob":
                  _isYesValue(motherLiving.value) ? motherJob.value : "",
              "motherPhone": _isYesValue(motherLiving.value)
                  ? motherPhoneNumber.value.text
                  : "",
              "motherLiving": motherLiving.value,
              "motherSalary": _isYesValue(motherLiving.value)
                  ? motherSalary.value.text
                  : "",
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
        CurrentUserService.instance.userId,
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
