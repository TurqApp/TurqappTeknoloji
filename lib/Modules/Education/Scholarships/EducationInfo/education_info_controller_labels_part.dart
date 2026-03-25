part of 'education_info_controller.dart';

extension EducationInfoControllerLabelsPart on EducationInfoController {
  String localizedFieldLabel(String label) {
    switch (label) {
      case 'Eğitim Seviyesi':
        return 'scholarship.education_level_label'.tr;
      case 'Ülke':
        return 'scholarship.country_label'.tr;
      case 'İl':
        return 'common.city'.tr;
      case 'İlçe':
        return 'common.district'.tr;
      case 'Okul':
        return 'education_info.middle_school'.tr;
      case 'Lise':
        return 'education_info.high_school'.tr;
      case 'Üniversite':
        return 'scholarship.applicant.university'.tr;
      case 'Fakülte':
        return 'scholarship.applicant.faculty'.tr;
      case 'Bölüm':
        return 'scholarship.applicant.department'.tr;
      case 'Sınıf':
        return 'education_info.class_level'.tr;
      default:
        return label;
    }
  }

  String localizedOption(String value) {
    switch (value) {
      case EducationInfoController._middleSchool:
        return 'education_info.level_middle_school'.tr;
      case EducationInfoController._highSchool:
        return 'education_info.level_high_school'.tr;
      case EducationInfoController._associate:
        return 'education_info.level_associate'.tr;
      case EducationInfoController._bachelor:
        return 'education_info.level_bachelor'.tr;
      case EducationInfoController._masters:
        return 'education_info.level_masters'.tr;
      case EducationInfoController._doctorate:
        return 'education_info.level_doctorate'.tr;
      case '5. Sınıf':
      case '6. Sınıf':
      case '7. Sınıf':
      case '8. Sınıf':
      case '9. Sınıf':
      case '10. Sınıf':
      case '11. Sınıf':
      case '12. Sınıf':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
      case '10':
      case '11':
      case '12':
        return 'education_info.class_grade'.trParams({
          'grade': value.split('.').first,
        });
      default:
        return value;
    }
  }

  String localizedPlaceholder(String label) {
    return 'education_info.select_field'
        .trParams({'field': localizedFieldLabel(label)});
  }
}
