import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/education_reference_data_service.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Models/Education/high_school_model.dart';
import 'package:turqappv2/Models/Education/higher_education_model.dart';
import 'package:turqappv2/Models/middle_school_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class EducationInfoController extends GetxController
    with GetTickerProviderStateMixin {
  static const String _middleSchool = 'Ortaokul';
  static const String _highSchool = 'Lise';
  static const String _associate = 'Önlisans';
  static const String _bachelor = 'Lisans';
  static const String _masters = 'Yüksek Lisans';
  static const String _doctorate = 'Doktora';
  final UserRepository _userRepository = UserRepository.ensure();
  final CurrentUserService _currentUserService = CurrentUserService.instance;
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final EducationReferenceDataService _referenceDataService =
      EducationReferenceDataService.ensure();
  RxString selectedEducationLevel = ''.obs;
  RxString content = ''.obs;
  RxBool isLoading = false.obs;
  RxBool isInitialLoading = true.obs;

  RxString selectedCountry = ''.obs;
  RxString selectedCity = ''.obs;
  RxString selectedDistrict = ''.obs;
  RxString selectedSchool = ''.obs;
  RxString selectedHighSchool = ''.obs;
  RxString selectedUniversity = ''.obs;
  RxString selectedFaculty = ''.obs;
  RxString selectedDepartment = ''.obs;
  RxString selectedClassLevel = ''.obs;
  RxList<String> countries = <String>[].obs;
  RxList<String> cities = <String>[].obs;
  RxList<CitiesModel> cityDistrictData = <CitiesModel>[].obs;
  RxList<MiddleSchoolModel> middleSchools = <MiddleSchoolModel>[].obs;
  RxList<HighSchoolModel> highSchools = <HighSchoolModel>[].obs;
  RxList<HigherEducationModel> higherEducations = <HigherEducationModel>[].obs;

  RxBool hasMiddleSchoolData = false.obs;
  RxBool hasHighSchoolData = false.obs;
  RxBool hasHigherEducationData = false.obs;

  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, RxDouble> _animationTurns = {};

  String get middleSchoolValue => _middleSchool;
  String get highSchoolValue => _highSchool;
  String get associateValue => _associate;
  String get bachelorValue => _bachelor;
  String get mastersValue => _masters;
  String get doctorateValue => _doctorate;

  @override
  void onInit() {
    super.onInit();
    _initAnimationControllers();
    loadInitialData();
  }

  String localizedFieldLabel(String label) {
    switch (label) {
      case 'Eğitim Seviyesi':
        return 'scholarship.education_level_label'.tr;
      case 'Ülke':
        return 'scholarship.country_label'.tr;
      case 'İl':
        return 'common.city'.tr;
      case 'İlçe':
        return 'common.district'.tr;
      case 'Okul':
        return 'education_info.middle_school'.tr;
      case 'Lise':
        return 'education_info.high_school'.tr;
      case 'Üniversite':
        return 'scholarship.applicant.university'.tr;
      case 'Fakülte':
        return 'scholarship.applicant.faculty'.tr;
      case 'Bölüm':
        return 'scholarship.applicant.department'.tr;
      case 'Sınıf':
        return 'education_info.class_level'.tr;
      default:
        return label;
    }
  }

  String localizedOption(String value) {
    switch (value) {
      case _middleSchool:
        return 'education_info.level_middle_school'.tr;
      case _highSchool:
        return 'education_info.level_high_school'.tr;
      case _associate:
        return 'education_info.level_associate'.tr;
      case _bachelor:
        return 'education_info.level_bachelor'.tr;
      case _masters:
        return 'education_info.level_masters'.tr;
      case _doctorate:
        return 'education_info.level_doctorate'.tr;
      case '5. Sınıf':
      case '6. Sınıf':
      case '7. Sınıf':
      case '8. Sınıf':
      case '9. Sınıf':
      case '10. Sınıf':
      case '11. Sınıf':
      case '12. Sınıf':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
      case '10':
      case '11':
      case '12':
        return 'education_info.class_grade'.trParams({
          'grade': value.split('.').first,
        });
      default:
        return value;
    }
  }

  String localizedPlaceholder(String label) {
    return 'education_info.select_field'
        .trParams({'field': localizedFieldLabel(label)});
  }

  void _initAnimationControllers() {
    final labels = [
      'Eğitim Seviyesi',
      'Ülke',
      'İl',
      'İlçe',
      'Okul',
      'Lise',
      'Üniversite',
      'Fakülte',
      'Bölüm',
      'Sınıf',
    ];
    for (var label in labels) {
      _animationControllers[label] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );
      _animationTurns[label] = 0.0.obs;
      _animationControllers[label]!.addListener(() {
        _animationTurns[label]!.value =
            _animationControllers[label]!.value * 0.5;
      });
    }
  }

  AnimationController getAnimationController(String label) {
    return _animationControllers[label]!;
  }

  RxDouble getAnimationTurns(String label) {
    return _animationTurns[label]!;
  }

  Future<void> loadInitialData() async {
    try {
      isInitialLoading.value = true;
      isLoading.value = true;
      await Future.wait([
        loadCountriesData(),
        loadCityDistrictData(),
        loadMiddleSchools(),
        loadHighSchools(),
        loadHigherEducations(),
        loadSavedData(),
      ]);
    } catch (e) {
      AppSnackbar('common.error'.tr, 'education_info.initial_load_failed'.tr);
    } finally {
      isInitialLoading.value = false;
      isLoading.value = false;
    }
  }

  Future<void> loadCountriesData() async {
    try {
      countries.value = await _referenceDataService.getCountries();
    } catch (e) {
      AppSnackbar('common.error'.tr, 'education_info.countries_load_failed'.tr);
    }
  }

  Future<void> loadCityDistrictData() async {
    try {
      cityDistrictData.value =
          await _cityDirectoryService.getCitiesAndDistricts();
      cities.value = await _cityDirectoryService.getSortedCities();
    } catch (e) {
      AppSnackbar('common.error'.tr, 'education_info.city_data_failed'.tr);
    }
  }

  Future<void> loadMiddleSchools() async {
    try {
      middleSchools.value = await _referenceDataService.getMiddleSchools();
    } catch (e) {
      AppSnackbar('common.error'.tr, 'education_info.middle_schools_failed'.tr);
    }
  }

  Future<void> loadHighSchools() async {
    try {
      highSchools.value = await _referenceDataService.getHighSchools();
    } catch (e) {
      AppSnackbar('common.error'.tr, 'education_info.high_schools_failed'.tr);
    }
  }

  Future<void> loadHigherEducations() async {
    try {
      higherEducations.value =
          await _referenceDataService.getHigherEducations();
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        'education_info.higher_education_failed'.tr,
      );
    }
  }

  void updateContent() {
    content.value = '';
  }

  Future<void> loadSavedData() async {
    try {
      final userId = _currentUserService.userId;
      if (userId.isEmpty) {
        AppSnackbar('common.error'.tr, 'scholarship.session_missing'.tr);
        return;
      }

      final data = await _userRepository.getUserRaw(userId);
      if (data != null) {
        String educationLevel = userString(
          data,
          key: 'educationLevel',
          scope: 'education',
        );
        selectedEducationLevel.value = educationLevel;

        clearFields();

        if (educationLevel == _middleSchool) {
          selectedCountry.value =
              userString(data, key: 'ulke', scope: 'profile');
          selectedCity.value = userString(data, key: 'il', scope: 'profile');
          selectedDistrict.value =
              userString(data, key: 'ilce', scope: 'profile');
          selectedSchool.value =
              userString(data, key: 'ortaOkul', scope: 'education');
          selectedClassLevel.value =
              userString(data, key: 'sinif', scope: 'education');
          hasMiddleSchoolData.value = true;
        } else if (educationLevel == _highSchool) {
          selectedCountry.value =
              userString(data, key: 'ulke', scope: 'profile');
          selectedCity.value = userString(data, key: 'il', scope: 'profile');
          selectedDistrict.value =
              userString(data, key: 'ilce', scope: 'profile');
          selectedHighSchool.value =
              userString(data, key: 'lise', scope: 'education');
          selectedClassLevel.value =
              userString(data, key: 'sinif', scope: 'education');
          hasHighSchoolData.value = true;
        } else if ([
          _associate,
          _bachelor,
          _masters,
          _doctorate,
        ].contains(educationLevel)) {
          selectedCountry.value =
              userString(data, key: 'ulke', scope: 'profile');
          selectedCity.value = userString(data, key: 'il', scope: 'profile');
          selectedUniversity.value =
              userString(data, key: 'universite', scope: 'education');
          selectedFaculty.value =
              userString(data, key: 'fakulte', scope: 'education');
          selectedDepartment.value =
              userString(data, key: 'bolum', scope: 'education');
          hasHigherEducationData.value = true;
        }
      }
    } catch (e) {
      AppSnackbar('common.error'.tr, 'education_info.saved_data_failed'.tr);
    }
  }

  Future<void> loadSavedDataForLevel(String level) async {
    try {
      isLoading.value = true;
      final userId = _currentUserService.userId;
      if (userId.isEmpty) {
        AppSnackbar('common.error'.tr, 'scholarship.session_missing'.tr);
        return;
      }

      final data = await _userRepository.getUserRaw(userId);
      if (data != null) {
        String savedLevel =
            userString(data, key: 'educationLevel', scope: 'education');

        clearFields();

        if (level == savedLevel) {
          if (level == _middleSchool) {
            selectedCountry.value =
                userString(data, key: 'ulke', scope: 'profile');
            selectedCity.value = userString(data, key: 'il', scope: 'profile');
            selectedDistrict.value =
                userString(data, key: 'ilce', scope: 'profile');
            selectedSchool.value =
                userString(data, key: 'ortaOkul', scope: 'education');
            selectedClassLevel.value =
                userString(data, key: 'sinif', scope: 'education');
            hasMiddleSchoolData.value = true;
          } else if (level == _highSchool) {
            selectedCountry.value =
                userString(data, key: 'ulke', scope: 'profile');
            selectedCity.value = userString(data, key: 'il', scope: 'profile');
            selectedDistrict.value =
                userString(data, key: 'ilce', scope: 'profile');
            selectedHighSchool.value =
                userString(data, key: 'lise', scope: 'education');
            selectedClassLevel.value =
                userString(data, key: 'sinif', scope: 'education');
            hasHighSchoolData.value = true;
          } else if ([
            _associate,
            _bachelor,
            _masters,
            _doctorate,
          ].contains(level)) {
            selectedCountry.value =
                userString(data, key: 'ulke', scope: 'profile');
            selectedCity.value = userString(data, key: 'il', scope: 'profile');
            selectedUniversity.value =
                userString(data, key: 'universite', scope: 'education');
            selectedFaculty.value =
                userString(data, key: 'fakulte', scope: 'education');
            selectedDepartment.value =
                userString(data, key: 'bolum', scope: 'education');
            hasHigherEducationData.value = true;
          }
        }
        selectedEducationLevel.value = level;
      }
    } catch (e) {
      AppSnackbar('common.error'.tr, 'education_info.level_load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  bool hasDataForLevel(String level) {
    if (level == _middleSchool) return hasMiddleSchoolData.value;
    if (level == _highSchool) return hasHighSchoolData.value;
    if ([_associate, _bachelor, _masters, _doctorate].contains(level)) {
      return hasHigherEducationData.value;
    }
    return false;
  }

  void clearFields() {
    selectedCountry.value = '';
    selectedCity.value = '';
    selectedDistrict.value = '';
    selectedSchool.value = '';
    selectedHighSchool.value = '';
    selectedUniversity.value = '';
    selectedFaculty.value = '';
    selectedDepartment.value = '';
    selectedClassLevel.value = '';
  }

  void clearOtherEducationFields(String currentLevel) {
    if (currentLevel != _middleSchool) {
      selectedSchool.value = '';
      selectedClassLevel.value = '';
      hasMiddleSchoolData.value = false;
    }
    if (currentLevel != _highSchool) {
      selectedHighSchool.value = '';
      selectedClassLevel.value = '';
      hasHighSchoolData.value = false;
    }
    if (![
      _associate,
      _bachelor,
      _masters,
      _doctorate,
    ].contains(currentLevel)) {
      selectedUniversity.value = '';
      selectedFaculty.value = '';
      selectedDepartment.value = '';
      hasHigherEducationData.value = false;
    }
    if (currentLevel != _middleSchool && currentLevel != _highSchool) {
      selectedDistrict.value = '';
    }
    if (![
      _middleSchool,
      _highSchool,
      _associate,
      _bachelor,
      _masters,
      _doctorate,
    ].contains(currentLevel)) {
      selectedCountry.value = '';
      selectedCity.value = '';
    }
  }

  Future<void> saveMiddleSchool() async {
    if (selectedCountry.value.isEmpty) {
      AppSnackbar('common.error'.tr, 'personal_info.select_country_error'.tr);
      return;
    }
    if (selectedCity.value.isEmpty) {
      AppSnackbar('common.error'.tr, 'education_info.select_city_error'.tr);
      return;
    }
    if (selectedDistrict.value.isEmpty) {
      AppSnackbar('common.error'.tr, 'education_info.select_district_error'.tr);
      return;
    }
    if (selectedSchool.value.isEmpty) {
      AppSnackbar(
        'common.error'.tr,
        'education_info.select_middle_school_error'.tr,
      );
      return;
    }
    if (selectedClassLevel.value.isEmpty) {
      AppSnackbar(
        'common.error'.tr,
        'education_info.select_class_level_error'.tr,
      );
      return;
    }

    try {
      isLoading.value = true;
      final userId = _currentUserService.userId;
      if (userId.isEmpty) {
        AppSnackbar('common.error'.tr, 'scholarship.session_missing'.tr);
        return;
      }

      await _userRepository.updateUserFields(userId, {
        ...scopedUserUpdate(
          scope: 'education',
          values: {
            'educationLevel': _middleSchool,
            'ortaOkul': selectedSchool.value,
            'sinif': selectedClassLevel.value,
            'lise': '',
            'universite': '',
            'fakulte': '',
            'bolum': '',
          },
        ),
        ...scopedUserUpdate(
          scope: 'profile',
          values: {
            'ulke': selectedCountry.value,
            'il': selectedCity.value,
            'ilce': selectedDistrict.value,
          },
        ),
      });

      hasMiddleSchoolData.value = true;
      selectedEducationLevel.value = _middleSchool;
      clearOtherEducationFields(_middleSchool);
      Get.back();

      AppSnackbar('common.success'.tr, 'education_info.saved'.tr);
    } catch (e) {
      print("Firestore Error: $e");
      AppSnackbar('common.error'.tr, 'education_info.save_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveHighSchool() async {
    if (selectedCountry.value.isEmpty) {
      AppSnackbar('common.error'.tr, 'personal_info.select_country_error'.tr);
      return;
    }
    if (selectedCity.value.isEmpty) {
      AppSnackbar('common.error'.tr, 'education_info.select_city_error'.tr);
      return;
    }
    if (selectedDistrict.value.isEmpty) {
      AppSnackbar('common.error'.tr, 'education_info.select_district_error'.tr);
      return;
    }
    if (selectedHighSchool.value.isEmpty) {
      AppSnackbar(
        'common.error'.tr,
        'education_info.select_high_school_error'.tr,
      );
      return;
    }
    if (selectedClassLevel.value.isEmpty) {
      AppSnackbar(
        'common.error'.tr,
        'education_info.select_class_level_error'.tr,
      );
      return;
    }

    try {
      isLoading.value = true;
      final userId = _currentUserService.userId;
      if (userId.isEmpty) {
        AppSnackbar('common.error'.tr, 'scholarship.session_missing'.tr);
        return;
      }

      await _userRepository.updateUserFields(userId, {
        ...scopedUserUpdate(
          scope: 'education',
          values: {
            'educationLevel': _highSchool,
            'lise': selectedHighSchool.value,
            'sinif': selectedClassLevel.value,
            'ortaOkul': '',
            'universite': '',
            'fakulte': '',
            'bolum': '',
          },
        ),
        ...scopedUserUpdate(
          scope: 'profile',
          values: {
            'ulke': selectedCountry.value,
            'il': selectedCity.value,
            'ilce': selectedDistrict.value,
          },
        ),
      });

      hasHighSchoolData.value = true;
      selectedEducationLevel.value = _highSchool;
      clearOtherEducationFields(_highSchool);
      Get.back();

      AppSnackbar('common.success'.tr, 'education_info.saved'.tr);
    } catch (e) {
      print("Firestore Error: $e");
      AppSnackbar('common.error'.tr, 'education_info.save_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveHigherEducation() async {
    if (selectedCountry.value.isEmpty) {
      AppSnackbar('common.error'.tr, 'personal_info.select_country_error'.tr);
      return;
    }
    if (selectedCity.value.isEmpty) {
      AppSnackbar('common.error'.tr, 'education_info.select_city_error'.tr);
      return;
    }
    if (selectedUniversity.value.isEmpty) {
      AppSnackbar(
        'common.error'.tr,
        'education_info.select_university_error'.tr,
      );
      return;
    }
    if (selectedFaculty.value.isEmpty) {
      AppSnackbar(
        'common.error'.tr,
        'education_info.select_faculty_error'.tr,
      );
      return;
    }
    if (selectedDepartment.value.isEmpty) {
      AppSnackbar(
        'common.error'.tr,
        'education_info.select_department_error'.tr,
      );
      return;
    }

    try {
      isLoading.value = true;
      final userId = _currentUserService.userId;
      if (userId.isEmpty) {
        AppSnackbar('common.error'.tr, 'scholarship.session_missing'.tr);
        return;
      }

      String educationLevel = selectedEducationLevel.value;

      await _userRepository.updateUserFields(userId, {
        ...scopedUserUpdate(
          scope: 'education',
          values: {
            'educationLevel': educationLevel,
            'universite': selectedUniversity.value,
            'fakulte': selectedFaculty.value,
            'bolum': selectedDepartment.value,
            'ortaOkul': '',
            'lise': '',
            'sinif': '',
          },
        ),
        ...scopedUserUpdate(
          scope: 'profile',
          values: {
            'ulke': selectedCountry.value,
            'il': selectedCity.value,
          },
        ),
      });

      hasHigherEducationData.value = true;
      clearOtherEducationFields(educationLevel);
      Get.back();

      AppSnackbar('common.success'.tr, 'education_info.saved'.tr);
    } catch (e) {
      print("Firestore Error: $e");
      AppSnackbar('common.error'.tr, 'education_info.save_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showBottomSheet(
    BuildContext context,
    List<String> items,
    String title,
    Function(String) onSelect, {
    String? selectedItem,
    bool isSearchable = false,
  }) async {
    final animationController = _animationControllers[title];
    if (animationController == null) return;

    animationController.forward();

    final localizedItems = items.map(localizedOption).toList();
    final localizedSelectedItem =
        selectedItem == null ? null : localizedOption(selectedItem);

    await ListBottomSheet.show(
      context: context,
      items: localizedItems,
      title: localizedFieldLabel(title),
      onSelect: (dynamic val) {
        final selectedIndex = localizedItems.indexOf(val as String);
        onSelect(selectedIndex >= 0 ? items[selectedIndex] : val);
      },
      selectedItem: localizedSelectedItem,
      isSearchable: isSearchable,
    );

    animationController.reverse();
  }

  @override
  void onClose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    _animationTurns.clear();
    super.onClose();
  }
}
