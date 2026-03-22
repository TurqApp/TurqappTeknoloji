part of 'education_info_controller.dart';

extension _EducationInfoControllerDataPart on EducationInfoController {
  Future<void> _loadInitialDataImpl() async {
    try {
      isInitialLoading.value = true;
      isLoading.value = true;
      await Future.wait([
        _loadCountriesDataImpl(),
        _loadCityDistrictDataImpl(),
        _loadMiddleSchoolsImpl(),
        _loadHighSchoolsImpl(),
        _loadHigherEducationsImpl(),
        _loadSavedDataImpl(),
      ]);
    } catch (_) {
      AppSnackbar('common.error'.tr, 'education_info.initial_load_failed'.tr);
    } finally {
      isInitialLoading.value = false;
      isLoading.value = false;
    }
  }

  Future<void> _loadCountriesDataImpl() async {
    try {
      countries.value = await _referenceDataService.getCountries();
    } catch (_) {
      AppSnackbar('common.error'.tr, 'education_info.countries_load_failed'.tr);
    }
  }

  Future<void> _loadCityDistrictDataImpl() async {
    try {
      cityDistrictData.value =
          await _cityDirectoryService.getCitiesAndDistricts();
      cities.value = await _cityDirectoryService.getSortedCities();
    } catch (_) {
      AppSnackbar('common.error'.tr, 'education_info.city_data_failed'.tr);
    }
  }

  Future<void> _loadMiddleSchoolsImpl() async {
    try {
      middleSchools.value = await _referenceDataService.getMiddleSchools();
    } catch (_) {
      AppSnackbar('common.error'.tr, 'education_info.middle_schools_failed'.tr);
    }
  }

  Future<void> _loadHighSchoolsImpl() async {
    try {
      highSchools.value = await _referenceDataService.getHighSchools();
    } catch (_) {
      AppSnackbar('common.error'.tr, 'education_info.high_schools_failed'.tr);
    }
  }

  Future<void> _loadHigherEducationsImpl() async {
    try {
      higherEducations.value =
          await _referenceDataService.getHigherEducations();
    } catch (_) {
      AppSnackbar(
        'common.error'.tr,
        'education_info.higher_education_failed'.tr,
      );
    }
  }

  Future<void> _loadSavedDataImpl() async {
    try {
      final userId = _currentUserService.userId;
      if (userId.isEmpty) {
        AppSnackbar('common.error'.tr, 'scholarship.session_missing'.tr);
        return;
      }

      final data = await _userRepository.getUserRaw(userId);
      if (data != null) {
        final educationLevel = userString(
          data,
          key: 'educationLevel',
          scope: 'education',
        );
        selectedEducationLevel.value = educationLevel;

        _clearFieldsImpl();

        if (educationLevel == EducationInfoController._middleSchool) {
          _applyMiddleSchoolData(data);
          hasMiddleSchoolData.value = true;
        } else if (educationLevel == EducationInfoController._highSchool) {
          _applyHighSchoolData(data);
          hasHighSchoolData.value = true;
        } else if (_isHigherEducationLevel(educationLevel)) {
          _applyHigherEducationData(data);
          hasHigherEducationData.value = true;
        }
      }
    } catch (_) {
      AppSnackbar('common.error'.tr, 'education_info.saved_data_failed'.tr);
    }
  }

  Future<void> _loadSavedDataForLevelImpl(String level) async {
    try {
      isLoading.value = true;
      final userId = _currentUserService.userId;
      if (userId.isEmpty) {
        AppSnackbar('common.error'.tr, 'scholarship.session_missing'.tr);
        return;
      }

      final data = await _userRepository.getUserRaw(userId);
      if (data != null) {
        final savedLevel =
            userString(data, key: 'educationLevel', scope: 'education');

        _clearFieldsImpl();

        if (level == savedLevel) {
          if (level == EducationInfoController._middleSchool) {
            _applyMiddleSchoolData(data);
            hasMiddleSchoolData.value = true;
          } else if (level == EducationInfoController._highSchool) {
            _applyHighSchoolData(data);
            hasHighSchoolData.value = true;
          } else if (_isHigherEducationLevel(level)) {
            _applyHigherEducationData(data);
            hasHigherEducationData.value = true;
          }
        }
        selectedEducationLevel.value = level;
      }
    } catch (_) {
      AppSnackbar('common.error'.tr, 'education_info.level_load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  bool _hasDataForLevelImpl(String level) {
    if (level == EducationInfoController._middleSchool) {
      return hasMiddleSchoolData.value;
    }
    if (level == EducationInfoController._highSchool) {
      return hasHighSchoolData.value;
    }
    if (_isHigherEducationLevel(level)) {
      return hasHigherEducationData.value;
    }
    return false;
  }

  void _clearFieldsImpl() {
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

  void _clearOtherEducationFieldsImpl(String currentLevel) {
    if (currentLevel != EducationInfoController._middleSchool) {
      selectedSchool.value = '';
      selectedClassLevel.value = '';
      hasMiddleSchoolData.value = false;
    }
    if (currentLevel != EducationInfoController._highSchool) {
      selectedHighSchool.value = '';
      selectedClassLevel.value = '';
      hasHighSchoolData.value = false;
    }
    if (!_isHigherEducationLevel(currentLevel)) {
      selectedUniversity.value = '';
      selectedFaculty.value = '';
      selectedDepartment.value = '';
      hasHigherEducationData.value = false;
    }
    if (currentLevel != EducationInfoController._middleSchool &&
        currentLevel != EducationInfoController._highSchool) {
      selectedDistrict.value = '';
    }
    if (!_isKnownEducationLevel(currentLevel)) {
      selectedCountry.value = '';
      selectedCity.value = '';
    }
  }

  bool _isHigherEducationLevel(String level) {
    return [
      EducationInfoController._associate,
      EducationInfoController._bachelor,
      EducationInfoController._masters,
      EducationInfoController._doctorate,
    ].contains(level);
  }

  bool _isKnownEducationLevel(String level) {
    return [
      EducationInfoController._middleSchool,
      EducationInfoController._highSchool,
      EducationInfoController._associate,
      EducationInfoController._bachelor,
      EducationInfoController._masters,
      EducationInfoController._doctorate,
    ].contains(level);
  }

  void _applyMiddleSchoolData(Map<String, dynamic> data) {
    selectedCountry.value = userString(data, key: 'ulke', scope: 'profile');
    selectedCity.value = userString(data, key: 'il', scope: 'profile');
    selectedDistrict.value = userString(data, key: 'ilce', scope: 'profile');
    selectedSchool.value =
        userString(data, key: 'ortaOkul', scope: 'education');
    selectedClassLevel.value =
        userString(data, key: 'sinif', scope: 'education');
  }

  void _applyHighSchoolData(Map<String, dynamic> data) {
    selectedCountry.value = userString(data, key: 'ulke', scope: 'profile');
    selectedCity.value = userString(data, key: 'il', scope: 'profile');
    selectedDistrict.value = userString(data, key: 'ilce', scope: 'profile');
    selectedHighSchool.value =
        userString(data, key: 'lise', scope: 'education');
    selectedClassLevel.value =
        userString(data, key: 'sinif', scope: 'education');
  }

  void _applyHigherEducationData(Map<String, dynamic> data) {
    selectedCountry.value = userString(data, key: 'ulke', scope: 'profile');
    selectedCity.value = userString(data, key: 'il', scope: 'profile');
    selectedUniversity.value =
        userString(data, key: 'universite', scope: 'education');
    selectedFaculty.value =
        userString(data, key: 'fakulte', scope: 'education');
    selectedDepartment.value =
        userString(data, key: 'bolum', scope: 'education');
  }
}
