part of 'create_scholarship_controller.dart';

class CreateScholarshipController extends GetxController {
  static const String allUniversitiesValue = 'Tüm Üniversiteler',
      turkeyCountryValue = 'Türkiye',
      applicationPlaceTurqAppValue = 'TurqApp',
      applicationPlaceWebsiteValue = 'Web Site';
  static const String targetAudiencePopulationValue = 'Nüfusa Göre',
      targetAudienceResidenceValue = 'İkamete Göre',
      targetAudienceAllTurkeyValue = 'Tüm Türkiye';
  static const String repayableYesValue = 'Evet', repayableNoValue = 'Hayır';
  static const String duplicateStatusCanReceiveValue = 'Alabilir';
  static const String duplicateStatusCannotReceiveExceptKykValue =
      'Alamaz (KYK Hariç)';
  static const String educationAudienceAllValue = 'Hepsi',
      educationAudienceMiddleSchoolValue = 'Ortaokul',
      educationAudienceHighSchoolValue = 'Lise',
      educationAudienceUndergraduateValue = 'Lisans';
  static const String degreeAssociateValue = 'Ön Lisans',
      degreeBachelorValue = 'Lisans',
      degreeMasterValue = 'Yüksek Lisans',
      degreePhdValue = 'Doktora';
  static const String educationAudienceAllExpandedValue =
      'Ortaokul, Lise, Lisans';
  final _state = _CreateScholarshipControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleCreateScholarshipControllerInit(this);
  }
}
