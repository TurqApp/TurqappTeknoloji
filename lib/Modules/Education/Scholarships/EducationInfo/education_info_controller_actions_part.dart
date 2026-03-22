part of 'education_info_controller.dart';

extension _EducationInfoControllerActionsPart on EducationInfoController {
  Future<void> _saveMiddleSchoolImpl() async {
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
            'educationLevel': EducationInfoController._middleSchool,
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
      selectedEducationLevel.value = EducationInfoController._middleSchool;
      _clearOtherEducationFieldsImpl(EducationInfoController._middleSchool);
      Get.back();

      AppSnackbar('common.success'.tr, 'education_info.saved'.tr);
    } catch (e) {
      print("Firestore Error: $e");
      AppSnackbar('common.error'.tr, 'education_info.save_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveHighSchoolImpl() async {
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
            'educationLevel': EducationInfoController._highSchool,
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
      selectedEducationLevel.value = EducationInfoController._highSchool;
      _clearOtherEducationFieldsImpl(EducationInfoController._highSchool);
      Get.back();

      AppSnackbar('common.success'.tr, 'education_info.saved'.tr);
    } catch (e) {
      print("Firestore Error: $e");
      AppSnackbar('common.error'.tr, 'education_info.save_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveHigherEducationImpl() async {
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

      final educationLevel = selectedEducationLevel.value;

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
      _clearOtherEducationFieldsImpl(educationLevel);
      Get.back();

      AppSnackbar('common.success'.tr, 'education_info.saved'.tr);
    } catch (e) {
      print("Firestore Error: $e");
      AppSnackbar('common.error'.tr, 'education_info.save_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _showBottomSheetImpl(
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
}
