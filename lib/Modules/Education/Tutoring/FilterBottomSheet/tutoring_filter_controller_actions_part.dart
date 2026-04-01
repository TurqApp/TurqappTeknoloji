part of 'tutoring_filter_controller_library.dart';

Future<void> _loadTutoringFilterCities(
    TutoringFilterController controller) async {
  try {
    controller.sehirlerVeIlcelerData.value =
        await controller._cityDirectoryService.getCitiesAndDistricts();
    controller.sehirler.value =
        await controller._cityDirectoryService.getSortedCities();
  } catch (_) {
    controller.sehirler.value = [];
  } finally {
    controller.isLoading.value = false;
  }
}

extension TutoringFilterControllerActionsPart on TutoringFilterController {
  Future<void> loadSehirler() => _loadTutoringFilterCities(this);

  void applyFilters() {
    List<TutoringModel> filteredList =
        List.from(tutoringController.tutoringList);

    if (selectedBranch.value != null && selectedBranch.value!.isNotEmpty) {
      filteredList = filteredList
          .where((tutoring) => tutoring.brans == selectedBranch.value)
          .toList();
    }

    if (selectedGender.value != null && selectedGender.value!.isNotEmpty) {
      filteredList = filteredList
          .where((tutoring) => tutoring.cinsiyet == selectedGender.value)
          .toList();
    }

    if (selectedLessonPlace.value != null &&
        selectedLessonPlace.value!.isNotEmpty) {
      filteredList = filteredList
          .where(
            (tutoring) => selectedLessonPlace.value!.any(
              (place) => tutoring.dersYeri.contains(place),
            ),
          )
          .toList();
    }

    if (maxPrice.value != null) {
      filteredList = filteredList
          .where((tutoring) => tutoring.fiyat <= maxPrice.value!)
          .toList();
    }
    if (minPrice.value != null) {
      filteredList = filteredList
          .where((tutoring) => tutoring.fiyat >= minPrice.value!)
          .toList();
    }

    if (selectedCity.value != null && selectedCity.value!.isNotEmpty) {
      filteredList = filteredList
          .where((tutoring) => tutoring.sehir == selectedCity.value)
          .toList();
    }
    if (selectedDistrict.value != null && selectedDistrict.value!.isNotEmpty) {
      filteredList = filteredList
          .where((tutoring) => tutoring.ilce == selectedDistrict.value)
          .toList();
    }

    _applyTutoringFilterSort(this, filteredList);
    tutoringController.tutoringList.value = filteredList;
    Get.back();
  }

  void clearFilters() {
    selectedBranch.value = null;
    selectedCity.value = null;
    selectedDistrict.value = null;
    selectedGender.value = null;
    selectedLessonPlace.value = [];
    selectedSort.value = null;
    maxPrice.value = null;
    minPrice.value = null;
    city.value = "";
    town.value = "";
    tutoringController.tutoringList.value = List.from(
      tutoringController.tutoringList,
    );
  }
}

void _applyTutoringFilterSort(
  TutoringFilterController controller,
  List<TutoringModel> list,
) {
  final sort = controller.selectedSort.value ?? '';
  if (sort == 'En Yeni') {
    list.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    return;
  }
  if (sort == 'En Çok Görüntülenen') {
    list.sort(
      (a, b) => (b.viewCount ?? 0).compareTo(a.viewCount ?? 0),
    );
    return;
  }
  if (sort == 'Bana En Yakın') {
    final userCity =
        (CurrentUserService.instance.currentUser?.city ?? '').trim();
    list.sort((a, b) {
      final aScore = a.sehir == userCity ? 1 : 0;
      final bScore = b.sehir == userCity ? 1 : 0;
      if (aScore != bScore) {
        return bScore.compareTo(aScore);
      }
      return b.timeStamp.compareTo(a.timeStamp);
    });
  }
}
