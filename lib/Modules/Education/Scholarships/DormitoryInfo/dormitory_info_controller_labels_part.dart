part of 'dormitory_info_controller.dart';

extension DormitoryInfoControllerLabels on DormitoryInfoController {
  String localizedAdminType(String value) {
    switch (value) {
      case DormitoryInfoController._publicAdminType:
        return 'dormitory.admin_public'.tr;
      case DormitoryInfoController._privateAdminType:
        return 'dormitory.admin_private'.tr;
      case DormitoryInfoController._selectAdminType:
        return 'dormitory.select_admin_type'.tr;
      default:
        return value;
    }
  }

  String localizedSelectLabel(String value) {
    switch (value) {
      case DormitoryInfoController._selectCity:
        return 'common.select_city'.tr;
      case DormitoryInfoController._selectDistrict:
        return 'common.select_district'.tr;
      case DormitoryInfoController._selectAdminType:
        return 'dormitory.select_admin_type'.tr;
      default:
        return value;
    }
  }

  bool _matchesValue(String value, Set<String> variants) =>
      variants.contains(value.trim());

  String normalizedAdminType(String value) {
    if (_matchesValue(value, const <String>{
      DormitoryInfoController._publicAdminType,
      'Public',
      'Öffentlich',
      'Publique',
      'Pubblico',
      'Государственный',
    })) {
      return DormitoryInfoController._publicAdminType;
    }
    if (_matchesValue(value, const <String>{
      DormitoryInfoController._privateAdminType,
      'Private',
      'Privat',
      'Privé',
      'Privato',
      'Частный',
    })) {
      return DormitoryInfoController._privateAdminType;
    }
    if (_matchesValue(value, const <String>{
      DormitoryInfoController._selectAdminType,
      'Select Administration',
      'Verwaltung wählen',
      'Choisir ladministration',
      'Seleziona amministrazione',
      'Выберите управление',
    })) {
      return DormitoryInfoController._selectAdminType;
    }
    return value;
  }

  String capitalize(String s) => capitalizeWords(s);
}
