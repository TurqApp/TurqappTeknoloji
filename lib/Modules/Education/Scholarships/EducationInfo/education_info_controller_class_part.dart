part of 'education_info_controller.dart';

class EducationInfoController extends GetxController
    with GetTickerProviderStateMixin {
  static const String _middleSchool = 'Ortaokul';
  static const String _highSchool = 'Lise';
  static const String _associate = 'Önlisans';
  static const String _bachelor = 'Lisans';
  static const String _masters = 'Yüksek Lisans';
  static const String _doctorate = 'Doktora';
  final _state = _EducationInfoControllerState();

  @override
  void onInit() {
    super.onInit();
    _EducationInfoControllerLifecyclePart(this).handleOnInit();
  }

  @override
  void onClose() {
    _EducationInfoControllerLifecyclePart(this).handleOnClose();
    super.onClose();
  }
}
