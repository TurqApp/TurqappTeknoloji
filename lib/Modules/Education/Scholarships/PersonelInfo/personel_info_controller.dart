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
  static const String _single = 'Bekar';
  static const String _married = 'Evli';
  static const String _divorced = 'Boşanmış';
  static const String _turkey = 'Türkiye';
  static const String _selectValue = 'Seçim Yap';
  static const String _none = 'Yok';
  static const String _working = 'Çalışıyor';
  static const String _notWorking = 'Çalışmıyor';
  static const String _male = 'Erkek';
  static const String _female = 'Kadın';
  static const String _hasReport = 'Var';
  final UserRepository _userRepository = UserRepository.ensure();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final tc = ''.obs;
  final medeniHal = _single.obs;
  final county = _turkey.obs;
  final cinsiyet = _selectValue.obs;
  final engelliRaporu = _none.obs;
  final calismaDurumu = _notWorking.obs;
  final city = ''.obs;
  final town = ''.obs;
  final selectedDate = Rxn<DateTime>();

  final originalTC = ''.obs;
  final originalMedeniHal = _single.obs;
  final originalCounty = _turkey.obs;
  final originalCinsiyet = _selectValue.obs;
  final originalEngelliRaporu = _none.obs;
  final originalCalismaDurumu = _notWorking.obs;
  final originalCity = ''.obs;
  final originalTown = ''.obs;
  final originalSelectedDate = Rxn<DateTime>();

  final isLoading = true.obs;
  final isSaving = false.obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
  final sehirler = <String>[].obs;

  final medeniHalList = [_single, _married, _divorced];
  final cinsiyetList = [_male, _female];
  final engelliRaporuList = [_hasReport, _none];
  final calismaDurumuList = [_working, _notWorking];
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

  String get defaultSelectValue => _selectValue;
  String get turkeyValue => _turkey;
  bool get isTurkeySelected => county.value == _turkey;

  @override
  void onInit() {
    super.onInit();
    loadCitiesAndTowns();
    fetchData();
    _initFieldConfigs();
    _initAnimationControllers();
  }

  String localizedStaticValue(String value) {
    switch (value) {
      case _selectValue:
        return 'common.select'.tr;
      case _single:
        return 'personal_info.marital_single'.tr;
      case _married:
        return 'personal_info.marital_married'.tr;
      case _divorced:
        return 'personal_info.marital_divorced'.tr;
      case _male:
        return 'personal_info.gender_male'.tr;
      case _female:
        return 'personal_info.gender_female'.tr;
      case _hasReport:
        return 'personal_info.disability_yes'.tr;
      case _none:
        return 'personal_info.disability_no'.tr;
      case _working:
        return 'personal_info.working_yes'.tr;
      case _notWorking:
        return 'personal_info.working_no'.tr;
      default:
        return value;
    }
  }

  String localizedFieldLabel(String label) {
    switch (label) {
      case 'Ülke':
        return 'scholarship.country_label'.tr;
      case 'Medeni Hal':
        return 'scholarship.applicant.marital_status'.tr;
      case 'Cinsiyet':
        return 'scholarship.applicant.gender'.tr;
      case 'Engel Durumu':
        return 'scholarship.applicant.disability_report'.tr;
      case 'Çalışma Durumu':
        return 'scholarship.applicant.employment_status'.tr;
      case 'İl':
        return 'scholarship.applicant.registry_city'.tr;
      case 'İlçe':
        return 'scholarship.applicant.registry_district'.tr;
      default:
        return label;
    }
  }

  String localizedFieldTitle(String title) {
    switch (title) {
      case 'Ülke Seç':
        return 'scholarship.select_country'.tr;
      case 'Medeni Hal Seç':
        return 'personal_info.select_marital_status'.tr;
      case 'Cinsiyet Seç':
        return 'personal_info.select_gender'.tr;
      case 'Engel Durumu Seç':
        return 'personal_info.select_disability'.tr;
      case 'Çalışma Durumu Seç':
        return 'personal_info.select_employment'.tr;
      case 'İl Seç':
        return 'common.select_city'.tr;
      case 'İlçe Seç':
        return 'common.select_district'.tr;
      default:
        return title;
    }
  }

  String localizedPlaceholder(String label) {
    switch (label) {
      case 'Ülke':
        return 'scholarship.select_country'.tr;
      case 'İl':
        return 'common.select_city'.tr;
      case 'İlçe':
        return 'common.select_district'.tr;
      default:
        return 'personal_info.select_field'
            .trParams({'field': localizedFieldLabel(label)});
    }
  }

  void _initFieldConfigs() {
    fieldConfigs = [
      FieldConfig(
        label: "Ülke",
        title: "personal_info.select_country_title".tr,
        value: county,
        items: countryList,
        onSelect: (val) {
          county.value = val;
          if (val != _turkey) {
            city.value = '';
            town.value = '';
          }
        },
        isSearchable: true,
      ),
      FieldConfig(
        label: "Medeni Hal",
        title: "personal_info.select_marital_status_title".tr,
        value: medeniHal,
        items: medeniHalList,
        onSelect: (val) => medeniHal.value = val,
      ),
      FieldConfig(
        label: "Cinsiyet",
        title: "personal_info.select_gender_title".tr,
        value: cinsiyet,
        items: cinsiyetList,
        onSelect: (val) => cinsiyet.value = val,
      ),
      FieldConfig(
        label: "Engel Durumu",
        title: "personal_info.select_disability_title".tr,
        value: engelliRaporu,
        items: engelliRaporuList,
        onSelect: (val) => engelliRaporu.value = val,
      ),
      FieldConfig(
        label: "Çalışma Durumu",
        title: "personal_info.select_work_status_title".tr,
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
      final localizedItems = config.items.map(localizedStaticValue).toList();
      await AppBottomSheet.show(
        context: context,
        items: localizedItems,
        title: localizedFieldTitle(config.title),
        onSelect: (dynamic val) {
          final selectedIndex = localizedItems.indexOf(val as String);
          config.onSelect(
            selectedIndex >= 0 ? config.items[selectedIndex] : val,
          );
        },
        selectedItem: config.value.value.isEmpty
            ? null
            : localizedStaticValue(config.value.value),
        isSearchable: config.isSearchable,
      );
    } else {
      // Use ListBottomSheet for other fields (e.g., Ülke, İl, İlçe)
      await ListBottomSheet.show(
        context: context,
        items: config.items,
        title: localizedFieldTitle(config.title),
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
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
          fallback: _single,
        );
        county.value = originalCounty.value = userString(
          data,
          key: "ulke",
          scope: "profile",
          fallback: _turkey,
        ).trim();
        cinsiyet.value = originalCinsiyet.value = userString(
          data,
          key: "cinsiyet",
          scope: "profile",
          fallback: _selectValue,
        );
        engelliRaporu.value = originalEngelliRaporu.value = userString(
          data,
          key: "engelliRaporu",
          scope: "family",
          fallback: _none,
        );
        calismaDurumu.value = originalCalismaDurumu.value = userString(
          data,
          key: "calismaDurumu",
          scope: "profile",
          fallback: _notWorking,
        );
        city.value = originalCity.value = (county.value == _turkey
            ? userString(data, key: "nufusSehir", scope: "profile")
            : "");
        town.value = originalTown.value = (county.value == _turkey
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
          'common.warning'.tr,
          'personal_info.user_data_missing'.tr,
        );
        resetToOriginal();
      }
    } catch (e) {
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      AppSnackbar('common.error'.tr, 'scholarship.session_missing'.tr);
      return;
    }

    if (county.value.isEmpty) {
      AppSnackbar('common.error'.tr, 'personal_info.select_country_error'.tr);
      return;
    }

    if (county.value == _turkey &&
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
            "nufusSehir": county.value == _turkey ? city.value : "",
            "nufusIlce": county.value == _turkey ? town.value : "",
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
      originalCity.value = county.value == _turkey ? city.value : "";
      originalTown.value = county.value == _turkey ? town.value : "";
      originalSelectedDate.value = selectedDate.value;
      Get.back();

      AppSnackbar('common.success'.tr, 'personal_info.saved'.tr);
    } catch (e) {
      print("Veri kaydedilirken hata.");
      AppSnackbar('common.error'.tr, 'personal_info.save_failed'.tr);
    } finally {
      isSaving.value = false;
    }
  }
}
