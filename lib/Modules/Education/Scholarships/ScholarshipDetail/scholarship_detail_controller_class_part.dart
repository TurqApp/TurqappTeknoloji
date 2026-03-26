part of 'scholarship_detail_controller.dart';

class ScholarshipDetailController extends GetxController {
  static const String _selectValue = 'Seçiniz';
  static const String _selectActionValue = 'Seçim Yap';
  static const String _selectJobValue = 'Meslek Seç';
  static const String _yesValue = 'Evet';
  static const String _middleSchool = 'Ortaokul';
  static const String _highSchool = 'Lise';
  final _state = _ScholarshipDetailControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleScholarshipDetailInit(this);
  }
}
