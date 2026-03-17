import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Models/job_model.dart';
import '../../Core/BottomSheets/list_bottom_sheet.dart';
import '../../Models/cities_model.dart';
import '../../Themes/app_assets.dart';

List<Map<String, dynamic>> _decodeJobCityDistrictList(String response) {
  final List<dynamic> data = json.decode(response) as List<dynamic>;
  return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
}

class JobFinderController extends GetxController {
  final JobRepository _jobRepository = JobRepository.ensure();
  final List<String> imgList = [
    AppAssets.practice1,
    AppAssets.practice2,
    AppAssets.practice3,
  ];

  // Tab management
  final innerTabIndex = 0.obs;
  final innerPageController = PageController();
  final innerTabTitles = [
    "Keşfet",
    "İlan Ver",
    "Başvurularım",
    "Kariyer Profili"
  ];

  RxList<JobModel> allJobs = <JobModel>[].obs;
  RxList<JobModel> list = <JobModel>[].obs;
  RxList<JobModel> aramaSonucu = <JobModel>[].obs;

  TextEditingController search = TextEditingController();
  var listingSelection = 0.obs;
  var sehir = "".obs;
  final sehirler = <String>[].obs;
  var short = 0.obs;
  var filtre = false.obs;
  var isLoading = false.obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
  var kullaniciSehiri = "".obs;
  int _searchRequestId = 0;
  double? _userLat;
  double? _userLong;

  @override
  void onInit() {
    super.onInit();
    loadSehirler();
    unawaited(_bootstrapStartData());
    search.addListener(_searchListener);
  }

  @override
  void onClose() {
    innerPageController.dispose();
    search.dispose();
    super.onClose();
  }

  void onInnerTabTap(int index) {
    innerTabIndex.value = index;
    innerPageController.jumpToPage(index);
  }

  void onInnerPageChanged(int index) {
    innerTabIndex.value = index;
  }

  Future<void> refreshJob(String docID) async {
    try {
      final updatedJob = await _jobRepository.fetchById(docID,
          preferCache: false, forceRefresh: true);
      if (updatedJob != null) {
        final index = list.indexWhere((e) => e.docID == docID);
        if (index != -1) {
          list[index] = _attachDistance(updatedJob);
          list.refresh();
        }
      }
    } catch (_) {}
  }

  void _searchListener() {
    final query = search.text.trim();
    if (query.length >= 2) {
      searchFromTypesense(query);
    } else {
      _searchRequestId++;
      aramaSonucu.clear();
    }
  }

  Future<void> searchFromTypesense(String query) async {
    final requestId = ++_searchRequestId;
    isLoading.value = true;
    try {
      final result = await TypesenseEducationSearchService.instance.searchHits(
        entity: EducationTypesenseEntity.job,
        query: query,
        limit: 40,
      );
      if (requestId != _searchRequestId || search.text.trim() != query) return;

      final results = _jobsFromTypesenseHits(result.hits);
      if (requestId != _searchRequestId || search.text.trim() != query) return;
      aramaSonucu.assignAll(results);
    } catch (_) {
      if (requestId == _searchRequestId) {
        aramaSonucu.clear();
      }
    } finally {
      if (requestId == _searchRequestId) {
        isLoading.value = false;
      }
    }
  }

  Future<void> _bootstrapStartData() async {
    try {
      final cached = await TypesenseEducationSearchService.instance.searchHits(
        entity: EducationTypesenseEntity.job,
        query: '*',
        limit: 150,
        cacheOnly: true,
      );
      final cachedJobs = _jobsFromTypesenseHits(cached.hits);
      if (cachedJobs.isNotEmpty) {
        list.assignAll(cachedJobs);
        allJobs.assignAll(cachedJobs);
        isLoading.value = false;
        unawaited(_hydrateLocationAndResort(cachedJobs));
        await getStartData(silent: true);
        return;
      }
    } catch (_) {}

    await getStartData();
  }

  Future<void> getStartData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final shouldShowLoader = !silent && list.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      final result = await TypesenseEducationSearchService.instance.searchHits(
        entity: EducationTypesenseEntity.job,
        query: '*',
        limit: 150,
        forceRefresh: forceRefresh,
      );
      final fetchedJobs = _jobsFromTypesenseHits(result.hits);
      list.assignAll(fetchedJobs);
      allJobs.assignAll(fetchedJobs);
      if (shouldShowLoader) {
        isLoading.value = false;
      }

      unawaited(_hydrateLocationAndResort(fetchedJobs));
    } catch (_) {
    } finally {
      if (shouldShowLoader || list.isEmpty) {
        isLoading.value = false;
      }
    }
  }

  Future<void> _hydrateLocationAndResort(List<JobModel> sourceJobs) async {
    try {
      var position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final userLat = position.latitude;
      final userLong = position.longitude;
      _userLat = userLat;
      _userLong = userLong;

      List<Placemark> placemarks =
          await placemarkFromCoordinates(userLat, userLong);

      if (placemarks.isNotEmpty) {
        final cityName = placemarks.first.administrativeArea ?? '';
        sehir.value = cityName;
        kullaniciSehiri.value = cityName;
      }

      final updatedJobs = sourceJobs.map((job) {
        double distanceInMeters = Geolocator.distanceBetween(
          userLat,
          userLong,
          job.lat,
          job.long,
        );
        double distanceInKm = distanceInMeters / 1000;

        return job.copyWith(
          kacKm: double.parse(distanceInKm.toStringAsFixed(2)),
        );
      }).toList();

      updatedJobs.sort((a, b) => a.kacKm.compareTo(b.kacKm));
      list.assignAll(updatedJobs);
      allJobs.assignAll(updatedJobs);
    } catch (_) {}
  }

  JobModel _attachDistance(JobModel job) {
    final userLat = _userLat;
    final userLong = _userLong;
    if (userLat == null || userLong == null) return job;

    final distanceInKm = Geolocator.distanceBetween(
          userLat,
          userLong,
          job.lat,
          job.long,
        ) /
        1000;
    return job.copyWith(kacKm: double.parse(distanceInKm.toStringAsFixed(2)));
  }

  Future<void> siralaTapped() async {
    final context = Get.context;
    if (context == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(sheetContext).padding.bottom + 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Sıralama",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold",
                  ),
                ),
                const SizedBox(height: 12),
                buildRow(0, "En Yeni", () {
                  short.value = 0;
                  applySorting(list);
                  Navigator.of(sheetContext).pop();
                }),
                buildRow(1, "Bana En Yakın", () {
                  short.value = 1;
                  applySorting(list);
                  Navigator.of(sheetContext).pop();
                }),
                buildRow(2, "En Çok Görüntülenen", () {
                  short.value = 2;
                  applySorting(list);
                  Navigator.of(sheetContext).pop();
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> filtreTapped() async {
    RxString selectedType = "".obs;

    final types = [
      "Tam Zamanlı",
      "Yarı Zamanlı",
      "Part-Time",
      "Uzaktan",
      "Hibrit"
    ];

    final context = Get.context;
    if (context == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(sheetContext).padding.bottom + 12,
            ),
            child: Obx(() {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Filtreler",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Çalışma Türü",
                    style: TextStyle(fontFamily: "MontserratMedium"),
                  ),
                  const SizedBox(height: 8),
                  ...types.map((type) => buildFilterRow(
                        type,
                        selectedType.value == type,
                        () {
                          selectedType.value =
                              selectedType.value == type ? "" : type;
                        },
                      )),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      filtre.value = true;

                      final filtered = allJobs.where((job) {
                        final matchCity = sehir.value.isEmpty ||
                            sehir.value == "Tüm Türkiye" ||
                            job.city == sehir.value;
                        final matchType = selectedType.value.isEmpty ||
                            job.calismaTuru
                                .map((e) => e.toLowerCase().trim())
                                .contains(
                                    selectedType.value.toLowerCase().trim());
                        return matchCity && matchType;
                      }).toList();

                      applySorting(filtered);
                      list.value = filtered;
                      Navigator.of(sheetContext).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Filtreyi Uygula",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      filtre.value = false;
                      short.value = 0;
                      list.value = allJobs.toList();
                      applySorting(list);
                      Navigator.of(sheetContext).pop();
                    },
                    child: const Center(
                      child: Text(
                        "Filtreleri Temizle",
                        style: TextStyle(
                          color: Colors.red,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  void applySorting(List<JobModel> jobs) {
    switch (short.value) {
      case 1:
        jobs.sort((a, b) => a.kacKm.compareTo(b.kacKm));
        break;
      case 2:
        jobs.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      default:
        jobs.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    }
  }

  List<JobModel> _jobsFromTypesenseHits(List<Map<String, dynamic>> hits) {
    final jobs = <JobModel>[];
    final seen = <String>{};
    for (final hit in hits) {
      final job = _attachDistance(JobModel.fromTypesenseHit(hit));
      if (job.docID.isEmpty || seen.contains(job.docID) || job.ended) {
        continue;
      }
      seen.add(job.docID);
      jobs.add(job);
    }
    return jobs;
  }

  Widget buildFilterRow(String text, bool isSelected, VoidCallback onSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onSelected,
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.black : Colors.white,
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black,
                fontFamily: "MontserratMedium",
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildRow(int selection, String text, VoidCallback onSelected) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: onSelected,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.grey),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        short.value == selection ? Colors.black : Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loadSehirler() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/CityDistrict.json');
      final data = await compute(_decodeJobCityDistrictList, response);
      sehirlerVeIlcelerData.value =
          data.map((json) => CitiesModel.fromJson(json)).toList();
      final sortedCities =
          sehirlerVeIlcelerData.map((item) => item.il).toSet().toList();
      sortTurkishStrings(sortedCities);
      sehirler.value = sortedCities;
      sehirler.insert(0, "Tüm Türkiye");
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showIlSec() async {
    final sehirlerlist = List<String>.from(sehirler);
    sehirlerlist.remove(sehir.value);
    sehirlerlist.insert(0, sehir.value);
    if (sehir.value != kullaniciSehiri.value) {
      sehirlerlist.insert(1, kullaniciSehiri.value);
    }
    final uniqueCities = sehirlerlist.toSet().toList();
    final pinned = <String>[];
    for (final city in uniqueCities) {
      if (city == sehir.value || city == kullaniciSehiri.value) {
        pinned.add(city);
      }
    }
    final others = uniqueCities
        .where((city) => !pinned.contains(city) && city != "Tüm Türkiye")
        .toList();
    sortTurkishStrings(others);
    final visibleCities = <String>[
      if (uniqueCities.contains("Tüm Türkiye")) "Tüm Türkiye",
      ...pinned.where((city) => city.isNotEmpty && city != "Tüm Türkiye"),
      ...others,
    ];
    Get.bottomSheet(
      SizedBox(
        height: Get.height / 2,
        child: ListBottomSheet(
          list: visibleCities,
          title: "Şehir Seç",
          startSelection: sehir.value,
          onBackData: (v) {
            sehir.value = v;

            filtre.value = false;
            short.value = 0;

            if (v == "Tüm Türkiye" || v.isEmpty) {
              list.value = allJobs.where((job) => !job.ended).toList();
            } else {
              list.value =
                  allJobs.where((job) => job.city == v && !job.ended).toList();
            }
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
}
