import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Models/Education/high_school_model.dart';
import 'package:turqappv2/Models/Education/higher_education_model.dart';
import 'package:turqappv2/Models/middle_school_model.dart';

List<String> _parseCountryNames(String response) {
  final List<dynamic> data = json.decode(response) as List<dynamic>;
  return data
      .map((item) => (item as Map<String, dynamic>)['name'] as String)
      .toList();
}

List<Map<String, dynamic>> _decodeJsonObjectList(String response) {
  final List<dynamic> data = json.decode(response) as List<dynamic>;
  return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
}

class EducationInfoController extends GetxController
    with GetTickerProviderStateMixin {
  final UserRepository _userRepository = UserRepository.ensure();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
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

  @override
  void onInit() {
    super.onInit();
    _initAnimationControllers();
    loadInitialData();
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
      AppSnackbar("Hata", "Başlangıç verileri yüklenemedi.");
    } finally {
      isInitialLoading.value = false;
      isLoading.value = false;
    }
  }

  Future<void> loadCountriesData() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/Countries.json',
      );
      countries.value = await compute(_parseCountryNames, response);
    } catch (e) {
      AppSnackbar("Hata", "Ülkeler yüklenemedi.");
    }
  }

  Future<void> loadCityDistrictData() async {
    try {
      cityDistrictData.value =
          await _cityDirectoryService.getCitiesAndDistricts();
      cities.value = await _cityDirectoryService.getSortedCities();
    } catch (e) {
      AppSnackbar("Hata", "İl-ilçe verileri yüklenemedi.");
    }
  }

  Future<void> loadMiddleSchools() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/MiddleSchool.json',
      );
      final data = await compute(_decodeJsonObjectList, response);
      middleSchools.value =
          data.map((json) => MiddleSchoolModel.fromJson(json)).toList();
    } catch (e) {
      AppSnackbar("Hata", "Okul verileri yüklenemedi.");
    }
  }

  Future<void> loadHighSchools() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/HighSchool.json',
      );
      final data = await compute(_decodeJsonObjectList, response);
      highSchools.value =
          data.map((json) => HighSchoolModel.fromJson(json)).toList();
    } catch (e) {
      AppSnackbar("Hata", "Lise verileri yüklenemedi.");
    }
  }

  Future<void> loadHigherEducations() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/HigherEducation.json',
      );
      final data = await compute(_decodeJsonObjectList, response);
      higherEducations.value =
          data.map((json) => HigherEducationModel.fromJson(json)).toList();
    } catch (e) {
      AppSnackbar("Hata", "Yükseköğretim verileri yüklenemedi.");
    }
  }

  void updateContent() {
    content.value = '';
  }

  Future<void> loadSavedData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppSnackbar("Hata", "Kullanıcı oturumu açık değil");
        return;
      }

      final data = await _userRepository.getUserRaw(user.uid);
      if (data != null) {
        String educationLevel = userString(
          data,
          key: 'educationLevel',
          scope: 'education',
        );
        selectedEducationLevel.value = educationLevel;

        clearFields();

        if (educationLevel == 'Ortaokul') {
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
        } else if (educationLevel == 'Lise') {
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
          'Önlisans',
          'Lisans',
          'Yüksek Lisans',
          'Doktora',
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
      AppSnackbar("Hata", "Kayıtlı veriler yüklenemedi.");
    }
  }

  Future<void> loadSavedDataForLevel(String level) async {
    try {
      isLoading.value = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppSnackbar("Hata", "Kullanıcı oturumu açık değil");
        return;
      }

      final data = await _userRepository.getUserRaw(user.uid);
      if (data != null) {
        String savedLevel =
            userString(data, key: 'educationLevel', scope: 'education');

        clearFields();

        if (level == savedLevel) {
          if (level == 'Ortaokul') {
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
          } else if (level == 'Lise') {
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
            'Önlisans',
            'Lisans',
            'Yüksek Lisans',
            'Doktora',
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
      AppSnackbar("Hata", "Seviye verileri yüklenemedi.");
    } finally {
      isLoading.value = false;
    }
  }

  bool hasDataForLevel(String level) {
    if (level == 'Ortaokul') return hasMiddleSchoolData.value;
    if (level == 'Lise') return hasHighSchoolData.value;
    if (['Önlisans', 'Lisans', 'Yüksek Lisans', 'Doktora'].contains(level)) {
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
    if (currentLevel != 'Ortaokul') {
      selectedSchool.value = '';
      selectedClassLevel.value = '';
      hasMiddleSchoolData.value = false;
    }
    if (currentLevel != 'Lise') {
      selectedHighSchool.value = '';
      selectedClassLevel.value = '';
      hasHighSchoolData.value = false;
    }
    if (![
      'Önlisans',
      'Lisans',
      'Yüksek Lisans',
      'Doktora',
    ].contains(currentLevel)) {
      selectedUniversity.value = '';
      selectedFaculty.value = '';
      selectedDepartment.value = '';
      hasHigherEducationData.value = false;
    }
    if (currentLevel != 'Ortaokul' && currentLevel != 'Lise') {
      selectedDistrict.value = '';
    }
    if (![
      'Ortaokul',
      'Lise',
      'Önlisans',
      'Lisans',
      'Yüksek Lisans',
      'Doktora',
    ].contains(currentLevel)) {
      selectedCountry.value = '';
      selectedCity.value = '';
    }
  }

  Future<void> saveMiddleSchool() async {
    if (selectedCountry.value.isEmpty) {
      AppSnackbar("Hata", "Lütfen bir ülke seçin.");
      return;
    }
    if (selectedCity.value.isEmpty) {
      AppSnackbar("Hata", "Lütfen bir il seçin.");
      return;
    }
    if (selectedDistrict.value.isEmpty) {
      AppSnackbar("Hata", "Lütfen bir ilçe seçin.");
      return;
    }
    if (selectedSchool.value.isEmpty) {
      AppSnackbar("Hata", "Lütfen bir ortaokul seçin.");
      return;
    }
    if (selectedClassLevel.value.isEmpty) {
      AppSnackbar("Hata", "Lütfen bir sınıf seviyesi seçin.");
      return;
    }

    try {
      isLoading.value = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppSnackbar("Hata", "Kullanıcı oturumu açık değil.");
        return;
      }

      await _userRepository.updateUserFields(user.uid, {
        ...scopedUserUpdate(
          scope: 'education',
          values: {
            'educationLevel': 'Ortaokul',
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
      selectedEducationLevel.value = 'Ortaokul';
      clearOtherEducationFields('Ortaokul');
      Get.back();

      AppSnackbar("Başarılı", "Eğitim Bilgileriniz kaydedildi.");
    } catch (e) {
      print("Firestore Error: $e");
      AppSnackbar("Hata", "Kayıt başarısız.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveHighSchool() async {
    if (selectedCountry.value.isEmpty) {
      AppSnackbar("Hata", "Lütfen bir ülke seçin.");
      return;
    }
    if (selectedCity.value.isEmpty) {
      AppSnackbar("Hata", "Lütfen bir il seçin.");
      return;
    }
    if (selectedDistrict.value.isEmpty) {
      AppSnackbar("Hata", "Lütfen bir ilçe seçin.");
      return;
    }
    if (selectedHighSchool.value.isEmpty) {
      AppSnackbar("Hata", "Lütfen bir lise seçin.");
      return;
    }
    if (selectedClassLevel.value.isEmpty) {
      AppSnackbar("Hata", "Lütfen bir sınıf seviyesi seçin.");
      return;
    }

    try {
      isLoading.value = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppSnackbar("Hata", "Kullanıcı oturumu açık değil.");
        return;
      }

      await _userRepository.updateUserFields(user.uid, {
        ...scopedUserUpdate(
          scope: 'education',
          values: {
            'educationLevel': 'Lise',
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
      selectedEducationLevel.value = 'Lise';
      clearOtherEducationFields('Lise');
      Get.back();

      AppSnackbar("Başarılı", "Eğitim Bilgileriniz Kaydedildi.");
    } catch (e) {
      print("Firestore Error: $e");
      AppSnackbar("Hata", "Kayıt başarısız.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveHigherEducation() async {
    if (selectedCountry.value.isEmpty) {
      AppSnackbar("Hata", "Lütfen bir ülke seçin.");
      return;
    }
    if (selectedCity.value.isEmpty) {
      AppSnackbar("Hata", "Lütfen bir il seçin.");
      return;
    }
    if (selectedUniversity.value.isEmpty) {
      AppSnackbar("Hata", "Lütfen bir üniversite seçin.");
      return;
    }
    if (selectedFaculty.value.isEmpty) {
      AppSnackbar("Hata", "Lütfen bir fakülte seçin.");
      return;
    }
    if (selectedDepartment.value.isEmpty) {
      AppSnackbar("Hata", "Lütfen bir bölüm seçin.");
      return;
    }

    try {
      isLoading.value = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppSnackbar("Hata", "Kullanıcı oturumu açık değil.");
        return;
      }

      String educationLevel = selectedEducationLevel.value;

      await _userRepository.updateUserFields(user.uid, {
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

      AppSnackbar("Başarılı", "Eğitim Bilgileriniz Kaydedildi.");
    } catch (e) {
      print("Firestore Error: $e");
      AppSnackbar("Hata", "Kayıt başarısız.");
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

    await ListBottomSheet.show(
      context: context,
      items: items,
      title: title,
      onSelect: (dynamic val) => onSelect(val as String),
      selectedItem: selectedItem,
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
