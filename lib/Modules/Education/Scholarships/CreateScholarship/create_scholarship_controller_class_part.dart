part of 'create_scholarship_controller.dart';

class CreateScholarshipController extends GetxController {
  static CreateScholarshipController ensure({
    required String tag,
    bool permanent = false,
  }) =>
      _ensureCreateScholarshipController(tag: tag, permanent: permanent);

  static CreateScholarshipController? maybeFind({required String tag}) =>
      _maybeFindCreateScholarshipController(tag: tag);

  static const String allUniversitiesValue = 'Tüm Üniversiteler';
  static const String turkeyCountryValue = 'Türkiye';
  static const String applicationPlaceTurqAppValue = 'TurqApp';
  static const String applicationPlaceWebsiteValue = 'Web Site';
  static const String targetAudiencePopulationValue = 'Nüfusa Göre';
  static const String targetAudienceResidenceValue = 'İkamete Göre';
  static const String targetAudienceAllTurkeyValue = 'Tüm Türkiye';
  static const String repayableYesValue = 'Evet';
  static const String repayableNoValue = 'Hayır';
  static const String duplicateStatusCanReceiveValue = 'Alabilir';
  static const String duplicateStatusCannotReceiveExceptKykValue =
      'Alamaz (KYK Hariç)';
  static const String educationAudienceAllValue = 'Hepsi';
  static const String educationAudienceMiddleSchoolValue = 'Ortaokul';
  static const String educationAudienceHighSchoolValue = 'Lise';
  static const String educationAudienceUndergraduateValue = 'Lisans';
  static const String degreeAssociateValue = 'Ön Lisans';
  static const String degreeBachelorValue = 'Lisans';
  static const String degreeMasterValue = 'Yüksek Lisans';
  static const String degreePhdValue = 'Doktora';
  static const String educationAudienceAllExpandedValue =
      'Ortaokul, Lise, Lisans';
  final _state = _CreateScholarshipControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleCreateScholarshipControllerInit(this);
  }
}
