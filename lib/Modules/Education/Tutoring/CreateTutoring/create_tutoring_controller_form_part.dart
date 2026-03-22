part of 'create_tutoring_controller.dart';

extension CreateTutoringControllerFormPart on CreateTutoringController {
  Future<void> _geocodeLocation() async {
    try {
      final query = town.isNotEmpty
          ? '$town, ${city.value}, ${'common.country_turkey'.tr}'
          : '${city.value}, ${'common.country_turkey'.tr}';
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        _lat = locations.first.latitude;
        _long = locations.first.longitude;
      }
    } catch (_) {
      _lat = null;
      _long = null;
    }
  }

  void toggleTimeSlot(String day, String slot) {
    final current = availability[day] ?? [];
    if (current.contains(slot)) {
      current.remove(slot);
    } else {
      current.add(slot);
    }
    if (current.isEmpty) {
      availability.remove(day);
    } else {
      availability[day] = current;
    }
    availability.refresh();
  }

  void showIlSec() {
    ListBottomSheet.show(
      context: Get.context!,
      items: sehirler,
      title: 'tutoring.create.city_select'.tr,
      selectedItem: city.value,
      onSelect: (v) {
        city.value = v.toString();
        cityController.text = v.toString();
        town = '';
        districtController.text = '';
        _geocodeLocation();
      },
    );
  }

  void showIlcelerSec() {
    final ilceListesi = sehirlerVeIlcelerData
        .where((doc) => doc.il == city.value && city.value.isNotEmpty)
        .map((doc) => doc.ilce)
        .toList();
    sortTurkishStrings(ilceListesi);

    ListBottomSheet.show(
      context: Get.context!,
      items: ilceListesi,
      title: 'tutoring.create.district_select'.tr,
      selectedItem: town,
      onSelect: (v) {
        town = v.toString();
        districtController.text = v.toString();
        _geocodeLocation();
      },
    );
  }

  Future<void> loadSehirler() async {
    try {
      sehirlerVeIlcelerData.value =
          await _cityDirectoryService.getCitiesAndDistricts();
      sehirler.value = await _cityDirectoryService.getSortedCities();
      await autoFillLocationIfNeeded(allowPermissionPrompt: !Platform.isIOS);
    } catch (_) {}
  }

  Future<void> autoFillLocationIfNeeded({
    bool allowPermissionPrompt = true,
  }) async {
    try {
      if (city.value.isNotEmpty && town.isNotEmpty) {
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!allowPermissionPrompt) {
          return;
        }
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return;
        }
      }

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        return;
      }

      final place = placemarks.first;
      final cityCandidates = <String>[
        (place.administrativeArea ?? '').trim(),
        (place.locality ?? '').trim(),
      ];
      final districtCandidates = <String>[
        (place.subAdministrativeArea ?? '').trim(),
        (place.subLocality ?? '').trim(),
        (place.locality ?? '').trim(),
      ];

      final matchedCity = _matchCity(cityCandidates);
      if (matchedCity != null) {
        city.value = matchedCity;
        cityController.text = matchedCity;
        final matchedDistrict = _matchDistrict(matchedCity, districtCandidates);
        if (matchedDistrict != null) {
          town = matchedDistrict;
          districtController.text = matchedDistrict;
        }
      }

      _lat = position.latitude;
      _long = position.longitude;
    } catch (_) {}
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    branchController.clear();
    priceController.clear();
    cityController.clear();
    districtController.text = '';
    selectedLessonPlace.value = '';
    selectedGender.value = '';
    city.value = '';
    town = '';
    images.clear();
    isPhoneOpen.value = false;
    selectedBranch.value = '';
    availability.clear();
    _lat = null;
    _long = null;
  }

  String? _matchCity(List<String> candidates) {
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      final exact = sehirler.firstWhereOrNull((item) => item == candidate);
      if (exact != null) return exact;
      final normalizedCandidate = normalizeLocationText(candidate);
      final fuzzy = sehirler.firstWhereOrNull(
        (item) => normalizeLocationText(item) == normalizedCandidate,
      );
      if (fuzzy != null) return fuzzy;
    }
    return null;
  }

  String? _matchDistrict(String matchedCity, List<String> candidates) {
    final districts = sehirlerVeIlcelerData
        .where((item) => item.il == matchedCity)
        .map((item) => item.ilce)
        .toSet()
        .toList();
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      final exact = districts.firstWhereOrNull((item) => item == candidate);
      if (exact != null) return exact;
      final normalizedCandidate = normalizeLocationText(candidate);
      final fuzzy = districts.firstWhereOrNull(
        (item) => normalizeLocationText(item) == normalizedCandidate,
      );
      if (fuzzy != null) return fuzzy;
    }
    return null;
  }
}
