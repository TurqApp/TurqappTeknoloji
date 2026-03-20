import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/Repositories/job_home_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Modules/JobFinder/JobContent/job_content_controller.dart';
import 'package:turqappv2/Modules/JobFinder/job_localization_utils.dart';
import '../../Core/BottomSheets/list_bottom_sheet.dart';
import '../../Models/cities_model.dart';
import '../../Themes/app_assets.dart';

class JobFinderController extends GetxController {
  static const int _fullBootstrapLimit = 150;
  static const String _listingSelectionPrefKeyPrefix =
      'pasaj_job_listing_selection';
  static const String _allTurkeyRaw = 'Tüm Türkiye';

  final JobHomeSnapshotRepository _jobHomeSnapshotRepository =
      JobHomeSnapshotRepository.ensure();
  final JobRepository _jobRepository = JobRepository.ensure();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final List<String> imgList = [
    AppAssets.practice1,
    AppAssets.practice2,
    AppAssets.practice3,
  ];

  // Tab management
  final innerTabIndex = 0.obs;
  final innerPageController = PageController();
  List<String> get innerTabTitles => [
        'pasaj.job_finder.tab.explore'.tr,
        'pasaj.job_finder.tab.create'.tr,
        'pasaj.job_finder.tab.applications'.tr,
        'pasaj.job_finder.tab.career_profile'.tr,
      ];

  RxList<JobModel> allJobs = <JobModel>[].obs;
  RxList<JobModel> list = <JobModel>[].obs;
  RxList<JobModel> aramaSonucu = <JobModel>[].obs;

  TextEditingController search = TextEditingController();
  var listingSelection = 0.obs;
  final RxBool listingSelectionReady = false.obs;
  var sehir = "".obs;
  final sehirler = <String>[].obs;
  var short = 0.obs;
  var filtre = false.obs;
  var isLoading = true.obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
  var kullaniciSehiri = "".obs;
  int _searchRequestId = 0;
  double? _userLat;
  double? _userLong;
  Position? _lastResolvedPosition;
  StreamSubscription<CachedResource<List<JobModel>>>? _homeSnapshotSub;
  Timer? _deferredLocationTimer;

  bool _sameJobEntries(List<JobModel> current, List<JobModel> next) {
    final currentKeys = current
        .map(
          (job) => [
            job.docID,
            job.logo,
            job.brand,
            job.meslek,
            job.ilanBasligi,
            job.city,
            job.town,
            job.timeStamp,
            job.viewCount,
            job.applicationCount,
            job.kacKm.toStringAsFixed(2),
            job.calismaTuru.join('|'),
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (job) => [
            job.docID,
            job.logo,
            job.brand,
            job.meslek,
            job.ilanBasligi,
            job.city,
            job.town,
            job.timeStamp,
            job.viewCount,
            job.applicationCount,
            job.kacKm.toStringAsFixed(2),
            job.calismaTuru.join('|'),
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  bool _sameJobList(List<JobModel> next) => _sameJobEntries(list, next);

  String get _allTurkeyLabel => 'pasaj.common.all_turkiye'.tr;
  bool isAllTurkeySelection(String value) =>
      value.trim().isEmpty ||
      value == _allTurkeyRaw ||
      value == _allTurkeyLabel;

  String _listingSelectionKeyFor(String uid) =>
      '${_listingSelectionPrefKeyPrefix}_$uid';

  Future<void> _restoreListingSelection() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      listingSelection.value = 0;
      listingSelectionReady.value = true;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_listingSelectionKeyFor(uid));
      listingSelection.value = stored == 1 ? 1 : 0;
    } catch (_) {
      listingSelection.value = 0;
    } finally {
      listingSelectionReady.value = true;
    }
  }

  Future<void> _persistListingSelection() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _listingSelectionKeyFor(uid),
        listingSelection.value == 1 ? 1 : 0,
      );
    } catch (_) {}
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_restoreListingSelection());
    loadSehirler();
    unawaited(_bootstrapStartData());
    search.addListener(_searchListener);
  }

  @override
  void onClose() {
    _homeSnapshotSub?.cancel();
    _deferredLocationTimer?.cancel();
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

  void toggleListingSelection() {
    listingSelection.value = listingSelection.value == 0 ? 1 : 0;
    unawaited(_persistListingSelection());
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
      final resource = await _jobHomeSnapshotRepository.search(
        query: query,
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        limit: 40,
        forceSync: true,
      );
      if (requestId != _searchRequestId || search.text.trim() != query) return;

      final results = resource.data ?? const <JobModel>[];
      if (requestId != _searchRequestId || search.text.trim() != query) return;
      final nextResults = _applyDistanceToJobs(results);
      if (!_sameJobEntries(aramaSonucu, nextResults)) {
        aramaSonucu.assignAll(nextResults);
      }
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
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await JobContentController.warmSavedIdsForCurrentUser();
    _homeSnapshotSub?.cancel();
    _homeSnapshotSub = _jobHomeSnapshotRepository
        .openHome(
          userId: currentUid,
          limit: _fullBootstrapLimit,
        )
        .listen(_applyHomeSnapshotResource);
  }

  Future<void> getStartData({
    bool silent = false,
    bool forceRefresh = false,
    int limit = _fullBootstrapLimit,
    bool deferLocationHydration = false,
  }) async {
    final shouldShowLoader = !silent && list.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      final resource = await _jobHomeSnapshotRepository.loadHome(
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        limit: limit,
        forceSync: forceRefresh,
      );
      final fetchedJobs = _applyCurrentSorting(
        resource.data ?? const <JobModel>[],
      );
      if (!_sameJobList(fetchedJobs)) {
        list.assignAll(fetchedJobs);
        allJobs.assignAll(fetchedJobs);
      }
      SilentRefreshGate.markRefreshed('jobs:home');
      if (shouldShowLoader) {
        isLoading.value = false;
      }

      if (deferLocationHydration) {
        _scheduleLocationHydration(fetchedJobs);
      } else {
        unawaited(_hydrateLocationAndResort(
          fetchedJobs,
          allowPermissionPrompt: false,
        ));
      }
    } catch (_) {
    } finally {
      if (shouldShowLoader || list.isEmpty) {
        isLoading.value = false;
      }
    }
  }

  void _scheduleLocationHydration(List<JobModel> sourceJobs) {
    _deferredLocationTimer?.cancel();
    _deferredLocationTimer = Timer(const Duration(milliseconds: 450), () {
      if (isClosed) return;
      unawaited(_hydrateLocationAndResort(
        sourceJobs,
        allowPermissionPrompt: false,
      ));
    });
  }

  Future<void> _hydrateLocationAndResort(
    List<JobModel> sourceJobs, {
    required bool allowPermissionPrompt,
  }) async {
    try {
      final position = await _resolveUserPosition(
        allowPermissionPrompt: allowPermissionPrompt,
      );
      if (position == null) {
        return;
      }
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

      final sortedJobs = _applyCurrentSorting(updatedJobs);
      list.assignAll(sortedJobs);
      allJobs.assignAll(sortedJobs);
    } catch (_) {}
  }

  Future<Position?> _resolveUserPosition({
    required bool allowPermissionPrompt,
  }) async {
    try {
      final lastResolved = _lastResolvedPosition;
      if (lastResolved != null) {
        return lastResolved;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!allowPermissionPrompt) {
          return await Geolocator.getLastKnownPosition();
        }
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return await Geolocator.getLastKnownPosition();
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _lastResolvedPosition = lastKnown;
        return lastKnown;
      }

      final current = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      _lastResolvedPosition = current;
      return current;
    } catch (_) {
      return null;
    }
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
                AppSheetHeader(title: "pasaj.job_finder.sort_title".tr),
                buildRow(0, "pasaj.job_finder.sort_newest".tr, () {
                  short.value = 0;
                  applySorting(list);
                  Navigator.of(sheetContext).pop();
                }),
                buildRow(1, "pasaj.job_finder.sort_nearest_me".tr, () {
                  short.value = 1;
                  applySorting(list);
                  Navigator.of(sheetContext).pop();
                }),
                buildRow(2, "pasaj.job_finder.sort_most_viewed".tr, () {
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
                  AppSheetHeader(title: "pasaj.market.filter.title".tr),
                  Text(
                    "pasaj.job_finder.create.work_type".tr,
                    style: const TextStyle(fontFamily: "MontserratMedium"),
                  ),
                  const SizedBox(height: 8),
                  ...types.map((type) => buildFilterRow(
                        localizeJobWorkType(type),
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
                        final matchCity = isAllTurkeySelection(sehir.value) ||
                            job.city == sehir.value;
                        final normalizedSelectedType = normalizeSearchText(
                          selectedType.value,
                        );
                        final matchType = selectedType.value.isEmpty ||
                            job.calismaTuru
                                .map(normalizeSearchText)
                                .contains(normalizedSelectedType);
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
                      child: Text(
                        "pasaj.market.filter.apply".tr,
                        style: const TextStyle(
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
                    child: Center(
                      child: Text(
                        "pasaj.job_finder.clear_filters".tr,
                        style: const TextStyle(
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

  List<JobModel> _applyDistanceToJobs(List<JobModel> jobs) {
    return jobs.map(_attachDistance).toList(growable: false);
  }

  List<JobModel> _applyCurrentSorting(List<JobModel> jobs) {
    final sorted = List<JobModel>.from(jobs);
    applySorting(sorted);
    return sorted;
  }

  void _applyHomeSnapshotResource(CachedResource<List<JobModel>> resource) {
    final jobs = resource.data ?? const <JobModel>[];
    if (jobs.isNotEmpty) {
      final withDistance = _applyCurrentSorting(_applyDistanceToJobs(jobs));
      if (!_sameJobList(withDistance)) {
        list.assignAll(withDistance);
        allJobs.assignAll(withDistance);
      }
      _scheduleLocationHydration(withDistance);
    }

    if (!resource.isRefreshing || jobs.isNotEmpty) {
      isLoading.value = false;
      return;
    }
    if (list.isEmpty) {
      isLoading.value = true;
    }
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
      sehirlerVeIlcelerData.value =
          await _cityDirectoryService.getCitiesAndDistricts();
      sehirler.value = await _cityDirectoryService.getSortedCities(
        includeAllTurkey: true,
      );
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
        .where((city) => !pinned.contains(city) && !isAllTurkeySelection(city))
        .toList();
    sortTurkishStrings(others);
    final visibleCities = <String>[
      if (uniqueCities.any(isAllTurkeySelection)) _allTurkeyLabel,
      ...pinned
          .where(
            (city) => city.isNotEmpty && !isAllTurkeySelection(city),
          )
          .map((city) => city),
      ...others,
    ];
    Get.bottomSheet(
      SizedBox(
        height: Get.height / 2,
        child: ListBottomSheet(
          list: visibleCities,
          title: "pasaj.job_finder.select_city".tr,
          startSelection: sehir.value,
          onBackData: (v) {
            sehir.value = v;

            filtre.value = false;
            short.value = 0;

            if (isAllTurkeySelection(v)) {
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
