part of 'family_info_controller.dart';

extension FamilyInfoControllerActionsPart on FamilyInfoController {
  void showIlSec() {
    Get.bottomSheet(
      ListBottomSheet(
        list: sehirler,
        title: 'common.select_city'.tr,
        startSelection: city.value,
        onBackData: (v) {
          city.value = v;
          town.value = '';
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
    final ilceListesi = sehirlerVeIlcelerData
        .where((doc) => doc.il == city.value && city.value.isNotEmpty)
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

    if (_isYesValue(fatherLiving.value)) {
      if (fatherName.value.text.isEmpty) {
        AppSnackbar(
          'common.warning'.tr,
          'scholarship.applicant.father_name'.tr,
        );
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
        AppSnackbar(
          'common.warning'.tr,
          'scholarship.applicant.father_job'.tr,
        );
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

    if (_isYesValue(motherLiving.value)) {
      if (motherName.value.text.isEmpty) {
        AppSnackbar(
          'common.warning'.tr,
          'scholarship.applicant.mother_name'.tr,
        );
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
        AppSnackbar(
          'common.warning'.tr,
          'scholarship.applicant.mother_job'.tr,
        );
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

    if (totalLiving.value.text.isEmpty) {
      AppSnackbar('common.warning'.tr, 'family_info.family_size'.tr);
      return;
    }
    if (_isSelectHomeOwnershipValue(evMulkiyeti.value)) {
      AppSnackbar(
        'common.warning'.tr,
        'scholarship.applicant.home_ownership'.tr,
      );
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

    try {
      await _userRepository.updateUserFields(
        CurrentUserService.instance.effectiveUserId,
        {
          ...scopedUserUpdate(
            scope: 'family',
            values: {
              'familyInfo': familyInfo.value,
              'fatherName':
                  _isYesValue(fatherLiving.value) ? fatherName.value.text : '',
              'fatherSurname': _isYesValue(fatherLiving.value)
                  ? fatherSurname.value.text
                  : '',
              'fatherJob':
                  _isYesValue(fatherLiving.value) ? fatherJob.value : '',
              'fatherPhone': _isYesValue(fatherLiving.value)
                  ? fatherPhoneNumber.value.text
                  : '',
              'fatherLiving': fatherLiving.value,
              'fatherSalary': _isYesValue(fatherLiving.value)
                  ? fatherSalary.value.text
                  : '',
              'motherName':
                  _isYesValue(motherLiving.value) ? motherName.value.text : '',
              'motherSurname': _isYesValue(motherLiving.value)
                  ? motherSurname.value.text
                  : '',
              'motherJob':
                  _isYesValue(motherLiving.value) ? motherJob.value : '',
              'motherPhone': _isYesValue(motherLiving.value)
                  ? motherPhoneNumber.value.text
                  : '',
              'motherLiving': motherLiving.value,
              'motherSalary': _isYesValue(motherLiving.value)
                  ? motherSalary.value.text
                  : '',
              'totalLiving': int.tryParse(totalLiving.value.text) ?? 0,
              'evMulkiyeti': evMulkiyeti.value,
            },
          ),
          ...scopedUserUpdate(
            scope: 'profile',
            values: {
              'ikametSehir': city.value,
              'ikametIlce': town.value,
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

  void resetFamilyInfo() async {
    try {
      await _userRepository.updateUserFields(
        CurrentUserService.instance.effectiveUserId,
        {
          ...scopedUserUpdate(
            scope: 'family',
            values: {
              'familyInfo': '',
              'fatherName': '',
              'fatherSurname': '',
              'fatherJob': '',
              'fatherPhone': '',
              'fatherLiving': _familyInfoSelectValue,
              'fatherSalary': '',
              'motherName': '',
              'motherSurname': '',
              'motherJob': '',
              'motherPhone': '',
              'motherLiving': _familyInfoSelectValue,
              'motherSalary': '',
              'totalLiving': 0,
              'evMulkiyeti': _familyInfoSelectHomeOwnership,
            },
          ),
          ...scopedUserUpdate(
            scope: 'profile',
            values: {
              'ikametSehir': '',
              'ikametIlce': '',
            },
          ),
        },
      );

      familyInfo.value = '';
      fatherName.value.clear();
      fatherSurname.value.clear();
      fatherSalary.value.clear();
      fatherPhoneNumber.value.clear();
      fatherLiving.value = _familyInfoSelectValue;
      fatherJob.value = _familyInfoSelectJob;
      motherName.value.clear();
      motherSurname.value.clear();
      motherSalary.value.clear();
      motherPhoneNumber.value.clear();
      motherLiving.value = _familyInfoSelectValue;
      motherJob.value = _familyInfoSelectJob;
      totalLiving.value.clear();
      evMulkiyeti.value = _familyInfoSelectHomeOwnership;
      city.value = '';
      town.value = '';

      Navigator.of(Get.context!).pop();
      AppSnackbar('common.success'.tr, 'family_info.reset_success'.tr);
    } catch (e) {
      AppSnackbar('common.error'.tr, 'family_info.reset_failed'.tr);
    }
  }
}
