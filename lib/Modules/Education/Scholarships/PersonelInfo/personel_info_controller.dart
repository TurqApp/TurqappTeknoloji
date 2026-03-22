import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'personel_info_controller_data_part.dart';
part 'personel_info_controller_form_part.dart';

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
  static PersonelInfoController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(PersonelInfoController(), tag: tag, permanent: permanent);
  }

  static PersonelInfoController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<PersonelInfoController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PersonelInfoController>(tag: tag);
  }

  static const String _countryFieldLabel = 'Ülke';
  static const String _maritalStatusFieldLabel = 'Medeni Hal';
  static const String _genderFieldLabel = 'Cinsiyet';
  static const String _disabilityFieldLabel = 'Engel Durumu';
  static const String _employmentFieldLabel = 'Çalışma Durumu';
  static const String _cityFieldLabel = 'İl';
  static const String _districtFieldLabel = 'İlçe';
  static const String _countryFieldTitleKey =
      'personal_info.select_country_title';
  static const String _maritalStatusFieldTitleKey =
      'personal_info.select_marital_status_title';
  static const String _genderFieldTitleKey =
      'personal_info.select_gender_title';
  static const String _disabilityFieldTitleKey =
      'personal_info.select_disability_title';
  static const String _employmentFieldTitleKey =
      'personal_info.select_work_status_title';
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
  final countryList = _countryList;

  late final List<FieldConfig> fieldConfigs;
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, RxDouble> _animationTurns = {};

  String get defaultSelectValue => _selectValue;
  String get turkeyValue => _turkey;
  String get singleValue => _single;
  String get noneValue => _none;
  String get notWorkingValue => _notWorking;
  bool get isTurkeySelected => county.value == _turkey;

  @override
  void onInit() {
    super.onInit();
    loadCitiesAndTowns();
    fetchData();
    initializeFieldConfigs();
    initializeAnimationControllers();
  }

  @override
  void onClose() {
    disposeAnimationControllers();
    super.onClose();
  }
}
