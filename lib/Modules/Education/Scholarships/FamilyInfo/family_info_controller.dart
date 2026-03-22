import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'family_info_controller_data_part.dart';
part 'family_info_controller_actions_part.dart';

class FamilyInfoController extends GetxController {
  static FamilyInfoController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(FamilyInfoController(), tag: tag, permanent: permanent);
  }

  static FamilyInfoController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<FamilyInfoController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<FamilyInfoController>(tag: tag);
  }

  static const String _selectValue = "Seçiniz";
  static const String _selectHomeOwnership = "Seçim Yap";
  static const String _selectJob = "Meslek Seç";
  static const String _yesValue = "Evet";
  static const String _noValue = "Hayır";
  static const String _ownedHome = "Kendinize Ait Ev";
  static const String _relativeHome = "Yakınınıza Ait Ev";
  static const String _lodgingHome = "Lojman";
  static const String _rentHome = "Kira";
  final UserRepository _userRepository = UserRepository.ensure();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final isLoading = true.obs;
  final familyInfo = ''.obs;

  final fatherName = TextEditingController().obs;
  final fatherSurname = TextEditingController().obs;
  final fatherSalary = TextEditingController().obs;
  final fatherPhoneNumber = TextEditingController().obs;
  final fatherLiving = _selectValue.obs;
  final fatherJob = _selectJob.obs;
  final motherName = TextEditingController().obs;
  final motherSurname = TextEditingController().obs;
  final motherSalary = TextEditingController().obs;
  final motherPhoneNumber = TextEditingController().obs;
  final motherLiving = _selectValue.obs;
  final motherJob = _selectJob.obs;
  final totalLiving = TextEditingController().obs;
  final evMulkiyeti = _selectHomeOwnership.obs;
  final city = "".obs;
  final town = "".obs;
  final ScrollController scrollController = ScrollController();

  final evevMulkiyeti =
      [_ownedHome, _relativeHome, _lodgingHome, _rentHome].obs;
  final living = [_yesValue, _noValue].obs;
  final sehirler = <String>[].obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;

  bool _matchesValue(String value, Set<String> variants) =>
      variants.contains(value.trim());

  bool _isSelectValue(String value) => _matchesValue(value, const <String>{
        _selectValue,
        'Select',
        'Auswählen',
        'Sélectionner',
        'Seleziona',
        'Выбрать',
      });
  bool _isSelectJobValue(String value) => _matchesValue(value, const <String>{
        _selectJob,
        'Select Job',
        'Beruf wählen',
        'Choisir une profession',
        'Seleziona professione',
        'Выберите профессию',
      });
  bool _isSelectHomeOwnershipValue(String value) =>
      _matchesValue(value, const <String>{
        _selectHomeOwnership,
        'Select',
        'Auswählen',
        'Sélectionner',
        'Seleziona',
        'Выбрать',
      });
  bool _isYesValue(String value) => _matchesValue(value, const <String>{
        _yesValue,
        'Yes',
        'Ja',
        'Oui',
        'Sì',
        'Si',
        'Да',
      });

  bool get isFatherUnselected => _isSelectValue(fatherLiving.value);
  bool get isMotherUnselected => _isSelectValue(motherLiving.value);
  bool get isFatherAlive => _isYesValue(fatherLiving.value);
  bool get isMotherAlive => _isYesValue(motherLiving.value);
  bool get isHomeOwnershipUnselected =>
      _isSelectHomeOwnershipValue(evMulkiyeti.value);

  String get defaultSelection => _selectValue;
  String get defaultHomeOwnershipSelection => _selectHomeOwnership;
  String get defaultJobSelection => _selectJob;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(() {
      FocusScope.of(Get.context!).unfocus();
    });
    loadSehirler();
    fetchFromFirestore();

    // Hayatta mı sorusu değiştiğinde ilgili alanları temizle
    ever(fatherLiving, (value) {
      if (!_isYesValue(value)) {
        _clearFatherFields();
      }
    });

    ever(motherLiving, (value) {
      if (!_isYesValue(value)) {
        _clearMotherFields();
      }
    });
  }

  String localizedSelection(String value) {
    switch (value) {
      case _selectValue:
      case _selectHomeOwnership:
        return 'common.select'.tr;
      case _selectJob:
        return 'family_info.select_job'.tr;
      case _yesValue:
        return 'common.yes'.tr;
      case _noValue:
        return 'common.no'.tr;
      case _ownedHome:
        return 'family_info.home_owned'.tr;
      case _relativeHome:
        return 'family_info.home_relative'.tr;
      case _lodgingHome:
        return 'family_info.home_lodging'.tr;
      case _rentHome:
        return 'family_info.home_rent'.tr;
      default:
        return value;
    }
  }
}
