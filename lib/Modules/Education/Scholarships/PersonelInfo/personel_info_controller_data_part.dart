part of 'personel_info_controller.dart';

extension PersonelInfoControllerDataPart on PersonelInfoController {
  Future<void> loadCitiesAndTowns() async {
    isLoading.value = true;
    try {
      sehirlerVeIlcelerData.value =
          await _cityDirectoryService.getCitiesAndDistricts();
      sehirler.value = await _cityDirectoryService.getSortedCities();
    } catch (e, stackTrace) {
      print("Şehir ve ilçe verileri yüklenirken hata: $e\n$stackTrace");
      AppSnackbar('common.error'.tr, 'personal_info.city_load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void updateCity(String newCity) {
    if (sehirler.contains(newCity)) {
      city.value = newCity;
      town.value = '';
    }
  }

  void updateTown(String newTown) {
    final validTowns = sehirlerVeIlcelerData
        .where((e) => e.il == city.value)
        .map((e) => e.ilce)
        .toList();
    if (validTowns.contains(newTown)) {
      town.value = newTown;
    }
  }

  Future<void> fetchData() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.session_missing'.tr);
      isLoading.value = false;
      return;
    }

    try {
      isLoading.value = true;
      final data = await _userRepository.getUserRaw(uid);
      if (data != null) {
        tc.value =
            originalTC.value = userString(data, key: "tc", scope: "profile");
        medeniHal.value = originalMedeniHal.value = userString(
          data,
          key: "medeniHal",
          scope: "profile",
          fallback: PersonelInfoController._single,
        );
        county.value = originalCounty.value = userString(
          data,
          key: "ulke",
          scope: "profile",
          fallback: PersonelInfoController._turkey,
        ).trim();
        cinsiyet.value = originalCinsiyet.value = userString(
          data,
          key: "cinsiyet",
          scope: "profile",
          fallback: PersonelInfoController._selectValue,
        );
        engelliRaporu.value = originalEngelliRaporu.value = userString(
          data,
          key: "engelliRaporu",
          scope: "family",
          fallback: PersonelInfoController._none,
        );
        calismaDurumu.value = originalCalismaDurumu.value = userString(
          data,
          key: "calismaDurumu",
          scope: "profile",
          fallback: PersonelInfoController._notWorking,
        );
        city.value = originalCity.value =
            county.value == PersonelInfoController._turkey
                ? userString(data, key: "nufusSehir", scope: "profile")
                : "";
        town.value = originalTown.value =
            county.value == PersonelInfoController._turkey
                ? userString(data, key: "nufusIlce", scope: "profile")
                : "";

        final dateStr = userString(data, key: "dogumTarihi", scope: "profile");
        if (dateStr.isNotEmpty) {
          try {
            selectedDate.value = originalSelectedDate.value = DateFormat(
              "dd.MM.yyyy",
              "tr_TR",
            ).parse(dateStr);
          } catch (e) {
            print("Tarih parse hatası: $e");
            selectedDate.value = originalSelectedDate.value = null;
          }
        } else {
          selectedDate.value = originalSelectedDate.value = null;
        }
      } else {
        AppSnackbar(
          'common.warning'.tr,
          'personal_info.user_data_missing'.tr,
        );
        resetToOriginal();
      }
    } catch (_) {
      print("Veri yüklenirken hata.");
      AppSnackbar('common.error'.tr, 'personal_info.load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void resetToOriginal() {
    tc.value = originalTC.value;
    medeniHal.value = originalMedeniHal.value;
    county.value = originalCounty.value;
    cinsiyet.value = originalCinsiyet.value;
    engelliRaporu.value = originalEngelliRaporu.value;
    calismaDurumu.value = originalCalismaDurumu.value;
    city.value = originalCity.value;
    town.value = originalTown.value;
    selectedDate.value = originalSelectedDate.value;
  }

  Future<void> saveData() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.session_missing'.tr);
      return;
    }

    if (county.value.isEmpty) {
      AppSnackbar('common.error'.tr, 'personal_info.select_country_error'.tr);
      return;
    }

    if (county.value == PersonelInfoController._turkey &&
        (city.value.isEmpty || town.value.isEmpty)) {
      AppSnackbar('common.error'.tr, 'personal_info.fill_city_district'.tr);
      return;
    }

    try {
      isSaving.value = true;
      final formattedDate = selectedDate.value != null
          ? DateFormat("dd.MM.yyyy", "tr_TR").format(selectedDate.value!)
          : "";

      await _userRepository.updateUserFields(uid, {
        ...scopedUserUpdate(
          scope: 'family',
          values: {"engelliRaporu": engelliRaporu.value},
        ),
        ...scopedUserUpdate(
          scope: 'profile',
          values: {
            "tc": tc.value,
            "medeniHal": medeniHal.value,
            "ulke": county.value,
            "nufusSehir": county.value == PersonelInfoController._turkey
                ? city.value
                : "",
            "nufusIlce": county.value == PersonelInfoController._turkey
                ? town.value
                : "",
            "cinsiyet": cinsiyet.value,
            "calismaDurumu": calismaDurumu.value,
            "dogumTarihi": formattedDate,
          },
        ),
      });

      originalTC.value = tc.value;
      originalMedeniHal.value = medeniHal.value;
      originalCounty.value = county.value;
      originalCinsiyet.value = cinsiyet.value;
      originalEngelliRaporu.value = engelliRaporu.value;
      originalCalismaDurumu.value = calismaDurumu.value;
      originalCity.value =
          county.value == PersonelInfoController._turkey ? city.value : "";
      originalTown.value =
          county.value == PersonelInfoController._turkey ? town.value : "";
      originalSelectedDate.value = selectedDate.value;
      Get.back();

      AppSnackbar('common.success'.tr, 'personal_info.saved'.tr);
    } catch (_) {
      print("Veri kaydedilirken hata.");
      AppSnackbar('common.error'.tr, 'personal_info.save_failed'.tr);
    } finally {
      isSaving.value = false;
    }
  }
}
