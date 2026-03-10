import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Models/job_model.dart';
import '../../Core/BottomSheets/list_bottom_sheet.dart';
import '../../Models/cities_model.dart';
import '../../Themes/app_assets.dart';

class JobFinderController extends GetxController {
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
    getStartData();
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
      final doc = await FirebaseFirestore.instance
          .collection(JobCollection.name)
          .doc(docID)
          .get();

      if (doc.exists) {
        final updatedJob = JobModel.fromMap(doc.data()!, doc.id);
        final index = list.indexWhere((e) => e.docID == docID);
        if (index != -1) {
          list[index] = updatedJob;
          list.refresh();
        }
      }
    } catch (e) {
      print("İlan güncelleme hatası: $e");
    }
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
      final docIds =
          await TypesenseEducationSearchService.instance.searchDocIds(
        entity: EducationTypesenseEntity.job,
        query: query,
        limit: 40,
      );
      if (requestId != _searchRequestId || search.text.trim() != query) return;

      final results = await _fetchJobsByDocIds(docIds);
      if (requestId != _searchRequestId || search.text.trim() != query) return;
      aramaSonucu.assignAll(results);
    } catch (e) {
      print("Arama hatası: $e");
      if (requestId == _searchRequestId) {
        aramaSonucu.clear();
      }
    } finally {
      if (requestId == _searchRequestId) {
        isLoading.value = false;
      }
    }
  }

  Future<void> getStartData() async {
    isLoading.value = true;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000);

      final snapshot = await FirebaseFirestore.instance
          .collection(JobCollection.name)
          .orderBy("timeStamp", descending: true)
          .limit(150)
          .get();

      final jobs = <JobModel>[];
      final expiredJobIds = <String>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final job = JobModel.fromMap(data, doc.id);

        if (job.timeStamp < thirtyDaysAgo && !job.ended) {
          expiredJobIds.add(doc.id);
          continue;
        }

        if (!job.ended) {
          jobs.add(job);
        }
      }

      jobs.shuffle();
      list.assignAll(jobs);
      allJobs.assignAll(jobs);
      isLoading.value = false;

      if (expiredJobIds.isNotEmpty) {
        unawaited(_markJobsEndedSilently(expiredJobIds));
      }

      unawaited(_hydrateLocationAndResort(jobs));
    } catch (e) {
      print("Hata oluştu: $e");
    } finally {
      if (list.isEmpty) {
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
    } catch (e) {
      print("Konum bazli is siralama hatasi: $e");
    }
  }

  Future<void> _markJobsEndedSilently(List<String> docIds) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final docId in docIds) {
        batch.update(
          FirebaseFirestore.instance.collection(JobCollection.name).doc(docId),
          {"ended": true},
        );
      }
      await batch.commit();
    } catch (e) {
      print("Eski ilanlar sessiz kapatilamadi: $e");
    }
  }

  Future<List<JobModel>> _fetchJobsByDocIds(List<String> docIds) async {
    final orderedIds = docIds.where((id) => id.trim().isNotEmpty).toList();
    if (orderedIds.isEmpty) return const [];

    final byId = <String, JobModel>{};
    const chunkSize = 10;

    for (var i = 0; i < orderedIds.length; i += chunkSize) {
      final end = (i + chunkSize > orderedIds.length)
          ? orderedIds.length
          : i + chunkSize;
      final chunk = orderedIds.sublist(i, end);
      final snapshot = await FirebaseFirestore.instance
          .collection(JobCollection.name)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        final model = JobModel.fromMap(doc.data(), doc.id);
        if (model.ended) continue;
        byId[doc.id] = _attachDistance(model);
      }
    }

    return orderedIds.where(byId.containsKey).map((id) => byId[id]!).toList();
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
                  "Sıralama Ölçütü",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold",
                  ),
                ),
                const SizedBox(height: 12),
                buildRow(0, "Önerilen Sıralama", () {
                  short.value = 0;
                  list.shuffle();
                  Navigator.of(sheetContext).pop();
                }),
                buildRow(1, "Maaş'a Göre (Önce En Yüksek)", () {
                  short.value = 1;
                  applySorting(list);
                  Navigator.of(sheetContext).pop();
                }),
                buildRow(2, "Maaş'a Göre (Önce En Düşük)", () {
                  short.value = 2;
                  applySorting(list);
                  Navigator.of(sheetContext).pop();
                }),
                buildRow(3, "Bana En Yakın", () {
                  short.value = 3;
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
    RxString selectedDeneyim = "".obs;

    final types = [
      "Tam Zamanlı",
      "Yarı Zamanlı",
      "Part-Time",
      "Uzaktan",
      "Hibrit"
    ];
    final deneyimSeviyeleri = ["Deneyimsiz", "Junior", "Mid-Level", "Senior"];

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
                    "Filtreleme Ölçütü",
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
                  const SizedBox(height: 12),
                  const Text(
                    "Deneyim Seviyesi",
                    style: TextStyle(fontFamily: "MontserratMedium"),
                  ),
                  const SizedBox(height: 8),
                  ...deneyimSeviyeleri.map((seviye) => buildFilterRow(
                        seviye,
                        selectedDeneyim.value == seviye,
                        () {
                          selectedDeneyim.value =
                              selectedDeneyim.value == seviye ? "" : seviye;
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
                        final matchDeneyim = selectedDeneyim.value.isEmpty ||
                            job.deneyimSeviyesi == selectedDeneyim.value;
                        return matchCity && matchType && matchDeneyim;
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
      case 1: // Önce En Yüksek
        jobs.sort((a, b) => b.maas1.compareTo(a.maas1));
        break;
      case 2: // Önce En Düşük
        jobs.sort((a, b) => a.maas1.compareTo(b.maas1));
        break;
      case 3:
        jobs.sort((a, b) => a.kacKm.compareTo(b.kacKm));
        break;
      default:
        jobs.shuffle();
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
      final String response =
          await rootBundle.loadString('assets/data/CityDistrict.json');
      final List<dynamic> data = json.decode(response);
      sehirlerVeIlcelerData.value =
          data.map((json) => CitiesModel.fromJson(json)).toList();
      sehirler.value =
          sehirlerVeIlcelerData.map((item) => item.il).toSet().toList();
      sehirler.insert(0, "Tüm Türkiye");
    } catch (e) {
      print("Error loading cities: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showIlSec() async {
    final sehirlerlist = sehirler;
    sehirlerlist.remove(sehir.value);
    sehirlerlist.insert(0, sehir.value);
    if (sehir.value != kullaniciSehiri.value) {
      sehirlerlist.insert(1, kullaniciSehiri.value);
    }
    Get.bottomSheet(
      SizedBox(
        height: Get.height / 2,
        child: ListBottomSheet(
          list: sehirlerlist.toSet().toList(),
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
