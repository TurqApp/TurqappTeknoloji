import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Models/cities_model.dart';

class FieldConfig {
  final String label;
  final String title;
  final RxString value;
  final List<String> items;
  final Function(String) onSelect;
  final bool isSearchable;

  FieldConfig({
    required this.label,
    required this.title,
    required this.value,
    required this.items,
    required this.onSelect,
    this.isSearchable = false,
  });
}

class PersonelInfoController extends GetxController
    with GetTickerProviderStateMixin {
  final UserRepository _userRepository = UserRepository.ensure();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final tc = ''.obs;
  final medeniHal = 'Bekar'.obs;
  final county = 'Türkiye'.obs;
  final cinsiyet = 'Seçim Yap'.obs;
  final engelliRaporu = 'Yok'.obs;
  final calismaDurumu = 'Çalışmıyor'.obs;
  final city = ''.obs;
  final town = ''.obs;
  final selectedDate = Rxn<DateTime>();

  final originalTC = ''.obs;
  final originalMedeniHal = 'Bekar'.obs;
  final originalCounty = 'Türkiye'.obs;
  final originalCinsiyet = 'Seçim Yap'.obs;
  final originalEngelliRaporu = 'Yok'.obs;
  final originalCalismaDurumu = 'Çalışmıyor'.obs;
  final originalCity = ''.obs;
  final originalTown = ''.obs;
  final originalSelectedDate = Rxn<DateTime>();

  final isLoading = true.obs;
  final isSaving = false.obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
  final sehirler = <String>[].obs;

  final medeniHalList = ['Bekar', 'Evli', 'Boşanmış'];
  final cinsiyetList = ['Erkek', 'Kadın'];
  final engelliRaporuList = ['Var', 'Yok'];
  final calismaDurumuList = ['Çalışıyor', 'Çalışmıyor'];
  final countryList = [
    "Türkiye",
    "Afganistan",
    "Almanya",
    "Amerika Birleşik Devletleri",
    "Arjantin",
    "Avustralya",
    "Avusturya",
    "Azerbaycan",
    "Bahreyn",
    "Bangladeş",
    "Belçika",
    "Birleşik Arap Emirlikleri",
    "Birleşik Krallık",
    "Bosna-Hersek",
    "Brezilya",
    "Çekya",
    "Çin",
    "Danimarka",
    "Endonezya",
    "Ermenistan",
    "Etiyopya",
    "Filipinler",
    "Finlandiya",
    "Fransa",
    "Gana",
    "Güney Afrika",
    "Güney Kore",
    "Gürcistan",
    "Hindistan",
    "Hırvatistan",
    "Hollanda",
    "Irak",
    "İran",
    "İsrail",
    "İsveç",
    "İsviçre",
    "İspanya",
    "İtalya",
    "Japonya",
    "Kamboçya",
    "Kanada",
    "Katar",
    "Kenya",
    "Kırgızistan",
    "Kuveyt",
    "Laos",
    "Lübnan",
    "Macaristan",
    "Malezya",
    "Meksika",
    "Moğolistan",
    "Mısır",
    "Myanmar",
    "Nepal",
    "Nijerya",
    "Norveç",
    "Özbekistan",
    "Pakistan",
    "Polonya",
    "Portekiz",
    "Rusya",
    "Singapur",
    "Slovakya",
    "Slovenya",
    "Sri Lanka",
    "Sırbistan",
    "Suudi Arabistan",
    "Suriye",
    "Tacikistan",
    "Tayland",
    "Türkmenistan",
    "Umman",
    "Ürdün",
    "Vietnam",
    "Yemen",
    "Yunanistan",
    "Yeni Zelanda",
  ];

  late final List<FieldConfig> fieldConfigs;
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, RxDouble> _animationTurns = {};

  @override
  void onInit() {
    super.onInit();
    loadCitiesAndTowns();
    fetchData();
    _initFieldConfigs();
    _initAnimationControllers();
  }

  void _initFieldConfigs() {
    fieldConfigs = [
      FieldConfig(
        label: "Ülke",
        title: "Ülke Seç",
        value: county,
        items: countryList,
        onSelect: (val) {
          county.value = val;
          if (val != "Türkiye") {
            city.value = '';
            town.value = '';
          }
        },
        isSearchable: true,
      ),
      FieldConfig(
        label: "Medeni Hal",
        title: "Medeni Hal Seç",
        value: medeniHal,
        items: medeniHalList,
        onSelect: (val) => medeniHal.value = val,
      ),
      FieldConfig(
        label: "Cinsiyet",
        title: "Cinsiyet Seç",
        value: cinsiyet,
        items: cinsiyetList,
        onSelect: (val) => cinsiyet.value = val,
      ),
      FieldConfig(
        label: "Engel Durumu",
        title: "Engel Durumu Seç",
        value: engelliRaporu,
        items: engelliRaporuList,
        onSelect: (val) => engelliRaporu.value = val,
      ),
      FieldConfig(
        label: "Çalışma Durumu",
        title: "Çalışma Durumu Seç",
        value: calismaDurumu,
        items: calismaDurumuList,
        onSelect: (val) => calismaDurumu.value = val,
      ),
    ];
  }

  void _initAnimationControllers() {
    for (var config in fieldConfigs) {
      _animationControllers[config.label] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );
      _animationTurns[config.label] = 0.0.obs;
      _animationControllers[config.label]!.addListener(() {
        _animationTurns[config.label]!.value =
            _animationControllers[config.label]!.value * 0.5;
      });
    }
    // Initialize for city and town dropdowns
    _animationControllers["İl"] = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationTurns["İl"] = 0.0.obs;
    _animationControllers["İl"]!.addListener(() {
      _animationTurns["İl"]!.value = _animationControllers["İl"]!.value * 0.5;
    });
    _animationControllers["İlçe"] = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationTurns["İlçe"] = 0.0.obs;
    _animationControllers["İlçe"]!.addListener(() {
      _animationTurns["İlçe"]!.value =
          _animationControllers["İlçe"]!.value * 0.5;
    });
  }

  AnimationController getAnimationController(String label) {
    return _animationControllers[label]!;
  }

  RxDouble getAnimationTurns(String label) {
    return _animationTurns[label]!;
  }

  Future<void> toggleDropdown(BuildContext context, FieldConfig config) async {
    final animationController = _animationControllers[config.label];
    if (animationController == null) return;

    animationController.forward();

    // Use AppBottomSheet for Medeni Hal, Cinsiyet, Engel Durumu, Çalışma Durumu
    if ([
      "Medeni Hal",
      "Cinsiyet",
      "Engel Durumu",
      "Çalışma Durumu",
    ].contains(config.label)) {
      await AppBottomSheet.show(
        context: context,
        items: config.items,
        title: config.title,
        onSelect: (dynamic val) => config.onSelect(val as String),
        selectedItem: config.value.value.isEmpty ? null : config.value.value,
        isSearchable: config.isSearchable,
      );
    } else {
      // Use ListBottomSheet for other fields (e.g., Ülke, İl, İlçe)
      await ListBottomSheet.show(
        context: context,
        items: config.items,
        title: config.title,
        onSelect: (dynamic val) => config.onSelect(val as String),
        selectedItem: config.value.value.isEmpty ? null : config.value.value,
        isSearchable: config.isSearchable,
      );
    }

    animationController.reverse();
  }

  @override
  void onClose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    _animationTurns.clear();
    super.onClose();
  }

  Future<void> loadCitiesAndTowns() async {
    isLoading.value = true;
    try {
      sehirlerVeIlcelerData.value =
          await _cityDirectoryService.getCitiesAndDistricts();
      sehirler.value = await _cityDirectoryService.getSortedCities();
    } catch (e, stackTrace) {
      print("Şehir ve ilçe verileri yüklenirken hata: $e\n$stackTrace");
      AppSnackbar("Hata", "Şehir ve ilçe verileri yüklenemedi.");
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      AppSnackbar("Hata", "Kullanıcı oturumu bulunamadı.");
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
          fallback: "Bekar",
        );
        county.value = originalCounty.value = userString(
          data,
          key: "ulke",
          scope: "profile",
          fallback: "Türkiye",
        ).trim();
        cinsiyet.value = originalCinsiyet.value = userString(
          data,
          key: "cinsiyet",
          scope: "profile",
          fallback: "Seçim Yap",
        );
        engelliRaporu.value = originalEngelliRaporu.value = userString(
          data,
          key: "engelliRaporu",
          scope: "family",
          fallback: "Yok",
        );
        calismaDurumu.value = originalCalismaDurumu.value = userString(
          data,
          key: "calismaDurumu",
          scope: "profile",
          fallback: "Çalışmıyor",
        );
        city.value = originalCity.value = (county.value == "Türkiye"
            ? userString(data, key: "nufusSehir", scope: "profile")
            : "");
        town.value = originalTown.value = (county.value == "Türkiye"
            ? userString(data, key: "nufusIlce", scope: "profile")
            : "");

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
          "Bilgi",
          "Kullanıcı verisi bulunamadı. Yeni kayıt oluşturabilirsiniz.",
        );
        resetToOriginal();
      }
    } catch (e) {
      print("Veri yüklenirken hata.");
      AppSnackbar("Hata", "Veriler yüklenemedi.");
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      AppSnackbar("Hata", "Kullanıcı oturumu bulunamadı.");
      return;
    }

    if (county.value.isEmpty) {
      AppSnackbar("Hata", "Lütfen ülkeyi seçin.");
      return;
    }

    if (county.value == "Türkiye" &&
        (city.value.isEmpty || town.value.isEmpty)) {
      AppSnackbar("Hata", "Lütfen şehir ve ilçe bilgilerini doldurun.");
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
            "nufusSehir": county.value == "Türkiye" ? city.value : "",
            "nufusIlce": county.value == "Türkiye" ? town.value : "",
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
      originalCity.value = county.value == "Türkiye" ? city.value : "";
      originalTown.value = county.value == "Türkiye" ? town.value : "";
      originalSelectedDate.value = selectedDate.value;
      Get.back();

      AppSnackbar("Başarılı", "Kişisel Bilgileriniz kaydedildi.");
    } catch (e) {
      print("Veri kaydedilirken hata.");
      AppSnackbar("Hata", "Bilgiler kaydedilemedi.");
    } finally {
      isSaving.value = false;
    }
  }
}
