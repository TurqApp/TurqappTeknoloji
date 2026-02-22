import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/JobModel.dart';
import '../../Core/BottomSheets/ListBottomSheet.dart';
import '../../Models/CitiesModel.dart';
import '../../Themes/AppAssets.dart';

class JobFinderController extends GetxController {
  final List<String> imgList = [
    AppAssets.practice1,
    AppAssets.practice2,
    AppAssets.practice3,
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

  @override
  void onInit() {
    super.onInit();
    loadSehirler();
    getStartData();
    search.addListener(_searchListener);
  }

  Future<void> refreshJob(String docID) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection("IsBul").doc(docID).get();
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
    if (query.length >= 3) {
      searchFromFirestore(query);
    } else {
      aramaSonucu.clear();
    }
  }

  Future<void> searchFromFirestore(String query) async {
    isLoading.value = true;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("IsBul")
          .where("ended", isEqualTo: false)
          .get();

      List<JobModel> allJobs = snapshot.docs.map((doc) {
        final data = doc.data();
        return JobModel.fromMap(data, doc.id);
      }).toList();

      List<JobModel> results = allJobs.where((job) {
        final tanim = job.isTanimi.toLowerCase();
        final marka = job.brand.toLowerCase();
        final meslek = job.meslek.toLowerCase();

        return tanim.contains(query.toLowerCase()) ||
            marka.contains(query.toLowerCase()) ||
            meslek.contains(query.toLowerCase());
      }).toList();

      aramaSonucu.value = results;
    } catch (e) {
      print("Arama hatası: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getStartData() async {
    isLoading.value = true;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000);

      final snapshot = await FirebaseFirestore.instance
          .collection("IsBul")
          .orderBy("timeStamp", descending: true)
          .limit(150)
          .get();

      List<JobModel> jobs = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final job = JobModel.fromMap(data, doc.id);

        if (job.timeStamp < thirtyDaysAgo && !job.ended) {
          await FirebaseFirestore.instance
              .collection("IsBul")
              .doc(doc.id)
              .update({"ended": true});
          print("🔕 Süresi dolan ilan kapatıldı: ${job.brand}");
          continue;
        }

        if (!job.ended) {
          jobs.add(job);
        }
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (!serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        jobs.shuffle();
        list.value = jobs;
        allJobs.value = jobs;
        isLoading.value = false;
        //
        // for (var job in jobs) {
        //   print(job.toMap());
        // }
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          list.value = jobs;
          allJobs.value = jobs;

          for (var job in jobs) {
            print(job.toMap());
          }
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      double userLat = position.latitude;
      double userLong = position.longitude;

      List<Placemark> placemarks =
          await placemarkFromCoordinates(userLat, userLong);

      if (placemarks.isNotEmpty) {
        final cityName = placemarks.first.administrativeArea ?? '';
        sehir.value = cityName;
        kullaniciSehiri.value = cityName;
      }

      List<JobModel> updatedJobs = jobs.map((job) {
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
      list.value = updatedJobs;
      allJobs.value = updatedJobs;

      for (var job in updatedJobs) {
        print(job.toMap());
      }
    } catch (e) {
      print("Hata oluştu: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> siralaTapped() async {
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
                  "Sıralama Ölçütü",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold",
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            buildRow(0, "Önerilen Sıralama", () {
              short.value = 0;
              list.shuffle();
              Get.back();
            }),
            buildRow(1, "Maaş'a Göre (Önce En Yüksek)", () {
              short.value = 1;
              applySorting(list);
              Get.back();
            }),
            buildRow(2, "Maaş'a Göre (Önce En Düşük)", () {
              short.value = 2;
              applySorting(list);
              Get.back();
            }),
            buildRow(3, "Bana En Yakın", () {
              short.value = 3;
              applySorting(list);
              Get.back();
            }),
            SizedBox(height: 12),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> filtreTapped() async {
    RxString selectedType = "".obs;

    final types = ["Tam Zamanlı", "Yarı Zamanlı", "Part-Time", "Uzaktan"];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Filtreleme Ölçütü",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text("Çalışma Türü",
                  style: TextStyle(fontFamily: "MontserratMedium")),
              SizedBox(height: 8),
              ...types.map((type) => buildFilterRow(
                    type,
                    selectedType.value == type,
                    () {
                      selectedType.value =
                          selectedType.value == type ? "" : type;
                    },
                  )),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  filtre.value = true;

                  // 🔎 Filtreyi uygula (şehir artık zaten sehir.value içinde)
                  List<JobModel> filtered = allJobs.where((job) {
                    final matchCity =
                        sehir.value.isEmpty || job.city == sehir.value;
                    final matchType = selectedType.value.isEmpty ||
                        job.calismaTuru
                            .map((e) => e.toLowerCase().trim())
                            .contains(selectedType.value.toLowerCase().trim());
                    return matchCity && matchType;
                  }).toList();

                  applySorting(filtered);
                  list.value = filtered;
                  Get.back();
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
                    "Filtreyi Uygula",
                    style: TextStyle(
                        color: Colors.white, fontFamily: "MontserratBold"),
                  ),
                ),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  filtre.value = false;
                  short.value = 0;
                  list.value = allJobs.toList();
                  applySorting(list);
                  Get.back();
                },
                child: Center(
                  child: Text(
                    "Filtreleri Temizle",
                    style: TextStyle(
                        color: Colors.red, fontFamily: "MontserratMedium"),
                  ),
                ),
              ),
              SizedBox(height: 10),
            ],
          );
        }),
      ),
      isScrollControlled: true,
    );
  }

  void applySorting(List<JobModel> jobs) {
    switch (short.value) {
      case 1:
        jobs.sort((a, b) => a.maas1.compareTo(b.maas1)); // Yüksek maaş
        break;
      case 2:
        jobs.sort((b, a) => a.maas1.compareTo(b.maas1)); // Düşük maaş
        break;
      case 3:
        jobs.sort((a, b) => a.kacKm.compareTo(b.kacKm)); // En yakın
        break;
      default:
        jobs.shuffle(); // Önerilen
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
            print("SELECTED $v");
            sehir.value = v;

            // 🔄 Filtre ve sıralamayı sıfırla
            filtre.value = false;
            short.value = 0;

            // ✅ Tüm Türkiye ise filtreleme yapma
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
