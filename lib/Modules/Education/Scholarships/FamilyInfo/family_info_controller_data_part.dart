part of 'family_info_controller.dart';

extension FamilyInfoControllerDataPart on FamilyInfoController {
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
        CurrentUserService.instance.effectiveUserId,
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
          fallback: FamilyInfoController._selectValue,
        );
        fatherJob.value = userString(
          data,
          key: 'fatherJob',
          scope: 'family',
          fallback: FamilyInfoController._selectJob,
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
          fallback: FamilyInfoController._selectValue,
        );
        motherJob.value = userString(
          data,
          key: 'motherJob',
          scope: 'family',
          fallback: FamilyInfoController._selectJob,
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
          fallback: FamilyInfoController._selectHomeOwnership,
        );
        city.value = userString(data, key: 'ikametSehir', scope: 'profile');
        town.value = userString(data, key: 'ikametIlce', scope: 'profile');
      } else {
        _resetToDefaults();
      }
    } catch (_) {}
  }

  void _resetToDefaults() {
    fatherLiving.value = FamilyInfoController._selectValue;
    fatherJob.value = FamilyInfoController._selectJob;
    motherLiving.value = FamilyInfoController._selectValue;
    motherJob.value = FamilyInfoController._selectJob;
    evMulkiyeti.value = FamilyInfoController._selectHomeOwnership;
  }

  void _clearFatherFields() {
    fatherName.value.clear();
    fatherSurname.value.clear();
    fatherSalary.value.clear();
    fatherPhoneNumber.value.clear();
    fatherJob.value = FamilyInfoController._selectJob;
  }

  void _clearMotherFields() {
    motherName.value.clear();
    motherSurname.value.clear();
    motherSalary.value.clear();
    motherPhoneNumber.value.clear();
    motherJob.value = FamilyInfoController._selectJob;
  }
}
