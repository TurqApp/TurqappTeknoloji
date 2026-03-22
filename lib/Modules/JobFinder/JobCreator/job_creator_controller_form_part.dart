part of 'job_creator_controller.dart';

extension JobCreatorControllerFormPart on JobCreatorController {
  Future<void> selectCalismaTuru() async => _selectCalismaTuruInternal();

  Future<void> _selectCalismaTuruInternal() async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'pasaj.job_finder.create.work_type'.tr,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold",
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: calismaTuruList.map((item) {
                return Obx(
                  () => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextButton(
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all<EdgeInsets>(
                          EdgeInsets.zero,
                        ),
                        minimumSize: WidgetStateProperty.all<Size>(Size.zero),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                      ),
                      onPressed: () {
                        if (selectedCalismaTuruList.contains(item)) {
                          selectedCalismaTuruList.remove(item);
                        } else {
                          selectedCalismaTuruList.add(item);
                        }
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              localizeJobWorkType(item),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                          Container(
                            width: 25,
                            height: 25,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4)),
                              color: selectedCalismaTuruList.contains(item)
                                  ? Colors.black
                                  : Colors.transparent,
                              border: Border.all(color: Colors.black),
                            ),
                            child: Icon(
                              CupertinoIcons.checkmark,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> selectYanHaklar(BuildContext context) async =>
      _selectYanHaklarInternal(context);

  Future<void> _selectYanHaklarInternal(BuildContext context) async {
    Get.bottomSheet(
      Container(
        height: Get.height / 2,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'pasaj.job_finder.create.benefits'.tr,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratBold",
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: yanHaklarList.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final item = yanHaklarList[index];
                  return Obx(() {
                    final isSelected = selectedYanHaklar.contains(item);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextButton(
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all<EdgeInsets>(
                            EdgeInsets.zero,
                          ),
                          minimumSize: WidgetStateProperty.all<Size>(Size.zero),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          overlayColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                        ),
                        onPressed: () {
                          if (isSelected) {
                            selectedYanHaklar.remove(item);
                          } else {
                            selectedYanHaklar.add(item);
                          }
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                localizeJobBenefit(item),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ),
                            Container(
                              width: 25,
                              height: 25,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                                color: isSelected
                                    ? Colors.black
                                    : Colors.transparent,
                                border: Border.all(color: Colors.black),
                              ),
                              child: Icon(
                                CupertinoIcons.checkmark,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
      isScrollControlled: true,
    ).then((_) {
      closeKeyboard(context);
    });
  }

  Future<void> selectCalismaGunleri() async => _selectCalismaGunleriInternal();

  Future<void> _selectCalismaGunleriInternal() async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'pasaj.job_finder.create.work_days'.tr,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratBold",
              ),
            ),
            SizedBox(height: 12),
            ...calismaGunleriList.map((item) {
              return Obx(
                () => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextButton(
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all<EdgeInsets>(
                        EdgeInsets.zero,
                      ),
                      minimumSize: WidgetStateProperty.all<Size>(Size.zero),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      overlayColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                    ),
                    onPressed: () {
                      if (selectedCalismaGunleri.contains(item)) {
                        selectedCalismaGunleri.remove(item);
                      } else {
                        selectedCalismaGunleri.add(item);
                      }
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            localizeJobDay(item),
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                        Container(
                          width: 25,
                          height: 25,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(4)),
                            color: selectedCalismaGunleri.contains(item)
                                ? Colors.black
                                : Colors.transparent,
                            border: Border.all(color: Colors.black),
                          ),
                          child: const Icon(
                            CupertinoIcons.checkmark,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 12),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> showMeslekSelector() async => _showMeslekSelectorInternal();

  Future<void> _showMeslekSelectorInternal() async {
    Get.bottomSheet(
      SizedBox(
        height: Get.height / 2,
        child: ListBottomSheet(
          list: allJobs,
          title: 'pasaj.job_finder.create.profession'.tr,
          startSelection: meslek.value,
          onBackData: (v) {
            meslek.value = v;
          },
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  Future<void> loadSehirler() async => _loadSehirlerInternal();

  Future<void> _loadSehirlerInternal() async {
    try {
      sehirlerVeIlcelerData.value =
          await _cityDirectoryService.getCitiesAndDistricts();
      sehirler.value = await _cityDirectoryService.getSortedCities();
    } catch (_) {}
  }

  Future<void> showSehirSelect() async => _showSehirSelectInternal();

  Future<void> _showSehirSelectInternal() async {
    Get.bottomSheet(
      SizedBox(
        height: Get.height / 2,
        child: ListBottomSheet(
          list: sehirler,
          title: 'pasaj.job_finder.select_city'.tr,
          startSelection: sehir.value,
          onBackData: (v) {
            sehir.value = v;
          },
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  Future<void> showIlceSelect() async => _showIlceSelectInternal();

  Future<void> _showIlceSelectInternal() async {
    final districts = sehirlerVeIlcelerData
        .where((val) => val.il == sehir.value)
        .map((e) => e.ilce)
        .toSet()
        .toList()
        .cast<String>();
    sortTurkishStrings(districts);
    Get.bottomSheet(
      SizedBox(
        height: Get.height / 2,
        child: ListBottomSheet(
          list: districts,
          title: 'pasaj.job_finder.create.select_district'.tr,
          startSelection: ilce.value,
          onBackData: (v) {
            ilce.value = v;
          },
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  Future<void> autoFillLocationIfNeeded({
    bool allowPermissionPrompt = true,
  }) async =>
      _autoFillLocationIfNeededInternal(
        allowPermissionPrompt: allowPermissionPrompt,
      );

  Future<void> _autoFillLocationIfNeededInternal({
    bool allowPermissionPrompt = true,
  }) async {
    try {
      if (sehir.value.isNotEmpty && ilce.value.isNotEmpty) {
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
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

      if (placemarks.isNotEmpty) {
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
          sehir.value = matchedCity;
          final matchedDistrict =
              _matchDistrict(matchedCity, districtCandidates);
          if (matchedDistrict != null) {
            ilce.value = matchedDistrict;
          }
        }
        lat.value = position.latitude.toDouble();
        long.value = position.longitude.toDouble();
        adres.value = [
          place.street,
          place.name,
          place.subLocality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }
    } catch (_) {}
  }

  String? _matchCity(List<String> candidates) {
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      final exact = sehirler.firstWhereOrNull((city) => city == candidate);
      if (exact != null) return exact;
      final normalizedCandidate = normalizeLocationText(candidate);
      final fuzzy = sehirler.firstWhereOrNull(
        (city) => normalizeLocationText(city) == normalizedCandidate,
      );
      if (fuzzy != null) return fuzzy;
    }
    return null;
  }

  String? _matchDistrict(String city, List<String> candidates) {
    final districts = sehirlerVeIlcelerData
        .where((item) => item.il == city)
        .map((item) => item.ilce)
        .toSet()
        .toList()
        .cast<String>();
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      final exact =
          districts.firstWhereOrNull((district) => district == candidate);
      if (exact != null) return exact;
      final normalizedCandidate = normalizeLocationText(candidate);
      final fuzzy = districts.firstWhereOrNull(
        (district) => normalizeLocationText(district) == normalizedCandidate,
      );
      if (fuzzy != null) return fuzzy;
    }
    return null;
  }
}
