part of 'create_scholarship_controller.dart';

extension CreateScholarshipControllerLabelsPart on CreateScholarshipController {
  Future<Map<String, dynamic>> _authorFieldsForCurrentUser() async {
    final uid = _currentUid;
    if (uid.isEmpty) {
      return const <String, dynamic>{
        'nickname': '',
        'displayName': '',
        'avatarUrl': '',
        'authorNickname': '',
        'authorDisplayName': '',
        'authorAvatarUrl': '',
        'rozet': '',
      };
    }
    final raw = await _userRepository.getUserRaw(
      uid,
      preferCache: true,
      cacheOnly: false,
    );
    final nickname = (raw?['nickname'] ?? '').toString().trim();
    final displayName = (raw?['displayName'] ?? '').toString().trim();
    final avatarUrl = (raw?['avatarUrl'] ?? '').toString().trim();
    final rozet = (raw?['rozet'] ?? '').toString().trim();
    return <String, dynamic>{
      'nickname': nickname,
      'displayName': displayName.isNotEmpty ? displayName : nickname,
      'avatarUrl': avatarUrl,
      'authorNickname': nickname,
      'authorDisplayName': displayName.isNotEmpty ? displayName : nickname,
      'authorAvatarUrl': avatarUrl,
      'rozet': rozet,
    };
  }

  String applicationPlaceDisplayLabel(String value) {
    switch (value) {
      case applicationPlaceTurqAppValue:
        return 'scholarship.application_place_turqapp'.tr;
      case 'Burs Web Site':
      case applicationPlaceWebsiteValue:
        return 'scholarship.application_place_website'.tr;
      default:
        return value;
    }
  }

  bool isWebsiteApplicationPlace(String value) =>
      value == applicationPlaceWebsiteValue || value == 'Burs Web Site';

  String awardMonthLabel(String value) {
    switch (value) {
      case 'Ocak':
        return 'common.month.january'.tr;
      case 'Şubat':
        return 'common.month.february'.tr;
      case 'Mart':
        return 'common.month.march'.tr;
      case 'Nisan':
        return 'common.month.april'.tr;
      case 'Mayıs':
        return 'common.month.may'.tr;
      case 'Haziran':
        return 'common.month.june'.tr;
      case 'Temmuz':
        return 'common.month.july'.tr;
      case 'Ağustos':
        return 'common.month.august'.tr;
      case 'Eylül':
        return 'common.month.september'.tr;
      case 'Ekim':
        return 'common.month.october'.tr;
      case 'Kasım':
        return 'common.month.november'.tr;
      case 'Aralık':
        return 'common.month.december'.tr;
      default:
        return value;
    }
  }

  String scholarshipRepayableLabel(String value) {
    switch (value) {
      case repayableYesValue:
        return 'common.yes'.tr;
      case repayableNoValue:
        return 'common.no'.tr;
      default:
        return value;
    }
  }

  String scholarshipDuplicateStatusLabel(String value) {
    switch (value) {
      case duplicateStatusCanReceiveValue:
        return 'scholarship.duplicate_status.can_receive'.tr;
      case duplicateStatusCannotReceiveExceptKykValue:
        return 'scholarship.duplicate_status.cannot_receive_except_kyk'.tr;
      default:
        return value;
    }
  }

  String scholarshipTargetAudienceLabel(String value) {
    switch (value) {
      case targetAudiencePopulationValue:
        return 'scholarship.target.population'.tr;
      case targetAudienceResidenceValue:
        return 'scholarship.target.residence'.tr;
      case targetAudienceAllTurkeyValue:
        return 'scholarship.target.all_turkiye'.tr;
      default:
        return value;
    }
  }

  String scholarshipEducationAudienceLabel(String value) {
    switch (value) {
      case educationAudienceAllValue:
        return 'scholarship.education.all'.tr;
      case educationAudienceMiddleSchoolValue:
        return 'scholarship.education.middle_school'.tr;
      case educationAudienceHighSchoolValue:
        return 'scholarship.education.high_school'.tr;
      case educationAudienceUndergraduateValue:
        return 'scholarship.education.undergraduate'.tr;
      case educationAudienceAllExpandedValue:
        return [
          'scholarship.education.middle_school'.tr,
          'scholarship.education.high_school'.tr,
          'scholarship.education.undergraduate'.tr,
        ].join(', ');
      default:
        return value;
    }
  }

  String scholarshipCountryLabel(String value) {
    switch (value) {
      case turkeyCountryValue:
        return 'common.country_turkey'.tr;
      default:
        return value;
    }
  }

  String scholarshipConditionLabel(String value) {
    switch (value) {
      case 'T.C. vatandaşı olmak.':
        return 'scholarship.condition.citizen'.tr;
      case 'En az lise düzeyinde öğrenim görüyor olmak.':
        return 'scholarship.condition.min_high_school'.tr;
      case 'Herhangi bir disiplin cezası almamış olmak.':
        return 'scholarship.condition.no_discipline'.tr;
      case 'Ailesinin aylık toplam gelirinin belirli bir seviyenin altında olması.':
        return 'scholarship.condition.family_income'.tr;
      case 'Başka bir kurumdan karşılıksız burs almıyor olmak.':
        return 'scholarship.condition.no_other_grant'.tr;
      case 'Örgün öğretim programında kayıtlı öğrenci olmak.':
        return 'scholarship.condition.formal_education'.tr;
      case 'Akademik not ortalamasının en az 2.50/4.00 olması.':
        return 'scholarship.condition.gpa'.tr;
      case 'Adli sicil kaydının temiz olması.':
        return 'scholarship.condition.clean_record'.tr;
      case 'İlan edilen son başvuru tarihine kadar başvuru yapılmış olması.':
        return 'scholarship.condition.apply_before_deadline'.tr;
      case 'Belirtilen belgelerin eksiksiz şekilde teslim edilmiş olması.':
        return 'scholarship.condition.documents_complete'.tr;
      case 'Burs başvuru formunun eksiksiz doldurulması.':
        return 'scholarship.condition.form_complete'.tr;
      case 'Burs verilen il/ilçede ikamet ediyor olmak (gerekiyorsa).':
        return 'scholarship.condition.residence'.tr;
      case 'Eğitim süresi boyunca düzenli olarak başarı göstereceğini taahhüt etmek.':
        return 'scholarship.condition.success_commitment'.tr;
      case 'Başvuru sırasında gerçeğe aykırı beyanda bulunmamak.':
        return 'scholarship.condition.truthful_declaration'.tr;
      case 'Bursu sağlayan kurumun düzenlediği mülakat veya değerlendirme süreçlerine katılmak.':
        return 'scholarship.condition.attend_evaluation'.tr;
      default:
        return value;
    }
  }

  String scholarshipDocumentLabel(String value) {
    switch (value) {
      case 'Kimlik Kart Fotoğrafı':
        return 'scholarship.document.id_card_photo'.tr;
      case 'Öğrenci Belgesi (E Devlet)':
        return 'scholarship.document.student_certificate'.tr;
      case 'Transkript Belgesi':
        return 'scholarship.document.transcript'.tr;
      case 'Adli Sicil Kaydı (E Devlet)':
        return 'scholarship.document.criminal_record'.tr;
      case 'Aile Nüfus Kayıt Belgesi (E Devlet)':
        return 'scholarship.document.family_registry'.tr;
      case 'YKS - AYT Sonuç Belgesi (ÖSYM)':
        return 'scholarship.document.exam_results'.tr;
      case 'SGK Hizmet Dökümü (E Devlet Kendisi)':
        return 'scholarship.document.sgk_self'.tr;
      case 'SGK Hizmet Dökümü (E Devlet Anne Ve Baba)':
        return 'scholarship.document.sgk_parents'.tr;
      case 'Tapu Tescil Belgesi (E Devlet Kendisi)':
        return 'scholarship.document.title_deed'.tr;
      case 'Engelli Sağlık Kurulu Raporu':
        return 'scholarship.document.disability_report'.tr;
      default:
        return value;
    }
  }

  String localizedConditionsText(String value) {
    return value
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map(scholarshipConditionLabel)
        .join('\n');
  }

  String localizedDocumentsText(
    Iterable<String> items, {
    String separator = '\n',
  }) {
    return items
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map(scholarshipDocumentLabel)
        .join(separator);
  }

  String universityLabel(String value) {
    return value == allUniversitiesValue
        ? 'scholarship.all_universities'.tr
        : value;
  }
}
