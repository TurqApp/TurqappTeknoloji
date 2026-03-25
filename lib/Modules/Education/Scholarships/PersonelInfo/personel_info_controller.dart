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
part 'personel_info_controller_labels_part.dart';
part 'personel_info_controller_form_part.dart';

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
