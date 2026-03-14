import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';

class TutoringFilterController extends GetxController {
  final TutoringController tutoringController = Get.find<TutoringController>();
  final isLoading = true.obs;

  var selectedBranch = Rx<String?>(null);
  var selectedCity = Rx<String?>(null);
  var selectedDistrict = Rx<String?>(null);
  var selectedGender = Rx<String?>(null);
  var selectedLessonPlace = Rx<List<String>?>([]);
  var maxPrice = Rx<double?>(null);
  var minPrice = Rx<double?>(null);
  final sehirler = <String>[].obs;
  final city = "".obs;
  final town = "".obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSehirler();
  }

  void showIlSec() {
    Get.bottomSheet(
      ListBottomSheet(
        list: sehirler,
        title: "Şehir Seç",
        startSelection: city.value,
        onBackData: (v) {
          city.value = v;
          selectedCity.value = v;
          town.value = "";
          selectedDistrict.value = null;
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  void showIlcelerSec() {
    final List<String> ilceListesi = sehirlerVeIlcelerData
        .where((doc) => doc.il == city.value && city.value.isNotEmpty)
        .map((doc) => doc.ilce)
        .toList();

    Get.bottomSheet(
      ListBottomSheet(
        list: ilceListesi,
        title: "İlçe Seç",
        startSelection: town.value,
        onBackData: (v) {
          town.value = v;
          selectedDistrict.value = v;
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  Future<void> loadSehirler() async {
    try {
      final String response = await DefaultAssetBundle.of(
        Get.context!,
      ).loadString('assets/data/CityDistrict.json');
      final List<dynamic> data = json.decode(response);
      sehirlerVeIlcelerData.value =
          data.map((json) => CitiesModel.fromJson(json)).toList();
      sehirler.value =
          sehirlerVeIlcelerData.map((item) => item.il).toSet().toList();
    } catch (_) {
      sehirler.value = []; // Hata durumunda boş liste ile devam et
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    // Orijinal listeyi kopyala
    List<TutoringModel> filteredList = List.from(
      tutoringController.tutoringList,
    );

    // Branş filtresi
    if (selectedBranch.value != null && selectedBranch.value!.isNotEmpty) {
      filteredList = filteredList
          .where((tutoring) => tutoring.brans == selectedBranch.value)
          .toList();
    }

    // Cinsiyet filtresi
    if (selectedGender.value != null && selectedGender.value!.isNotEmpty) {
      filteredList = filteredList
          .where((tutoring) => tutoring.cinsiyet == selectedGender.value)
          .toList();
    }

    // Ders yeri filtresi
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

    // Fiyat aralığı filtresi
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

    // Şehir ve ilçe filtresi (ayrı bir kontrolle)
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

    // Sıralama ölçütü
    if (selectedLessonPlace.value != null &&
        selectedLessonPlace.value!.isNotEmpty) {
      final sortCriteria = selectedLessonPlace.value!.firstWhere(
        (criteria) => [
          'En Yeniler',
          'Fiyat: Düşükten Yükseğe',
          'Fiyat: Yüksekten Düşüğe',
        ].contains(criteria),
        orElse: () => '',
      );
      if (sortCriteria.isNotEmpty) {
        filteredList.sort((a, b) {
          if (sortCriteria == 'En Yeniler') {
            return b.timeStamp.compareTo(a.timeStamp);
          } else if (sortCriteria == 'Fiyat: Düşükten Yükseğe') {
            return a.fiyat.compareTo(b.fiyat);
          } else if (sortCriteria == 'Fiyat: Yüksekten Düşüğe') {
            return b.fiyat.compareTo(a.fiyat);
          }
          return 0;
        });
      }
    }

    // Filtrelenmiş listeyi güncelle
    tutoringController.tutoringList.value = filteredList;
    Get.back(); // Bottom sheet'i kapat
  }

  void clearFilters() {
    selectedBranch.value = null;
    selectedCity.value = null;
    selectedDistrict.value = null;
    selectedGender.value = null;
    selectedLessonPlace.value = [];
    maxPrice.value = null;
    minPrice.value = null;
    city.value = "";
    town.value = "";
    tutoringController.tutoringList.value = List.from(
      tutoringController.tutoringList,
    ); // Orijinal listeyi geri yükle
  }
}
