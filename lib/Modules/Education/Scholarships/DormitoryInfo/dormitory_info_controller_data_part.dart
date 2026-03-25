part of 'dormitory_info_controller.dart';

extension DormitoryInfoControllerDataPart on DormitoryInfoController {
  void _loadInitialData() {
    loadSehirler();
    fetchYurtData();
    fetchFirestoreData();
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
        CurrentUserService.instance.effectiveUserId,
      );
      if (data != null) {
        yurt.value = userString(
          data,
          key: 'yurt',
          scope: 'family',
        );
      }
    } catch (_) {}
  }
}
