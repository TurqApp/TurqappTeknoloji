part of 'family_info_controller.dart';

extension FamilyInfoControllerRuntimeX on FamilyInfoController {
  bool _matchesValue(String value, Set<String> variants) =>
      variants.contains(value.trim());

  bool _isSelectValue(String value) => _matchesValue(value, const <String>{
        _familyInfoSelectValue,
        'Select',
        'Auswählen',
        'Sélectionner',
        'Seleziona',
        'Выбрать',
      });
  bool _isSelectJobValue(String value) => _matchesValue(value, const <String>{
        _familyInfoSelectJob,
        'Select Job',
        'Beruf wählen',
        'Choisir une profession',
        'Seleziona professione',
        'Выберите профессию',
      });
  bool _isSelectHomeOwnershipValue(String value) =>
      _matchesValue(value, const <String>{
        _familyInfoSelectHomeOwnership,
        'Select',
        'Auswählen',
        'Sélectionner',
        'Seleziona',
        'Выбрать',
      });
  bool _isYesValue(String value) => _matchesValue(value, const <String>{
        _familyInfoYesValue,
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

  String get defaultSelection => _familyInfoSelectValue;
  String get defaultHomeOwnershipSelection => _familyInfoSelectHomeOwnership;
  String get defaultJobSelection => _familyInfoSelectJob;

  void _handleOnInit() {
    scrollController.addListener(() {
      FocusScope.of(Get.context!).unfocus();
    });
    loadSehirler();
    fetchFromFirestore();

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
      case _familyInfoSelectValue:
      case _familyInfoSelectHomeOwnership:
        return 'common.select'.tr;
      case _familyInfoSelectJob:
        return 'family_info.select_job'.tr;
      case _familyInfoYesValue:
        return 'common.yes'.tr;
      case _familyInfoNoValue:
        return 'common.no'.tr;
      case _familyInfoOwnedHome:
        return 'family_info.home_owned'.tr;
      case _familyInfoRelativeHome:
        return 'family_info.home_relative'.tr;
      case _familyInfoLodgingHome:
        return 'family_info.home_lodging'.tr;
      case _familyInfoRentHome:
        return 'family_info.home_rent'.tr;
      default:
        return value;
    }
  }
}
