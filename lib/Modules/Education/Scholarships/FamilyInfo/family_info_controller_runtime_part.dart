part of 'family_info_controller.dart';

extension FamilyInfoControllerRuntimeX on FamilyInfoController {
  bool _matchesValue(String value, Set<String> variants) =>
      variants.contains(value.trim());

  bool _isSelectValue(String value) => _matchesValue(value, const <String>{
        FamilyInfoController._selectValue,
        'Select',
        'Auswählen',
        'Sélectionner',
        'Seleziona',
        'Выбрать',
      });
  bool _isSelectJobValue(String value) => _matchesValue(value, const <String>{
        FamilyInfoController._selectJob,
        'Select Job',
        'Beruf wählen',
        'Choisir une profession',
        'Seleziona professione',
        'Выберите профессию',
      });
  bool _isSelectHomeOwnershipValue(String value) =>
      _matchesValue(value, const <String>{
        FamilyInfoController._selectHomeOwnership,
        'Select',
        'Auswählen',
        'Sélectionner',
        'Seleziona',
        'Выбрать',
      });
  bool _isYesValue(String value) => _matchesValue(value, const <String>{
        FamilyInfoController._yesValue,
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

  String get defaultSelection => FamilyInfoController._selectValue;
  String get defaultHomeOwnershipSelection =>
      FamilyInfoController._selectHomeOwnership;
  String get defaultJobSelection => FamilyInfoController._selectJob;

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
      case FamilyInfoController._selectValue:
      case FamilyInfoController._selectHomeOwnership:
        return 'common.select'.tr;
      case FamilyInfoController._selectJob:
        return 'family_info.select_job'.tr;
      case FamilyInfoController._yesValue:
        return 'common.yes'.tr;
      case FamilyInfoController._noValue:
        return 'common.no'.tr;
      case FamilyInfoController._ownedHome:
        return 'family_info.home_owned'.tr;
      case FamilyInfoController._relativeHome:
        return 'family_info.home_relative'.tr;
      case FamilyInfoController._lodgingHome:
        return 'family_info.home_lodging'.tr;
      case FamilyInfoController._rentHome:
        return 'family_info.home_rent'.tr;
      default:
        return value;
    }
  }
}
