part of 'dormitory_info_controller.dart';

class DormitoryInfoController extends GetxController {
  static const String _selectCity = "Şehir Seç";
  static const String _selectDistrict = "İlçe Seç";
  static const String _selectAdminType = "İdari Seç";
  static const String _publicAdminType = "DEVLET";
  static const String _privateAdminType = "ÖZEL";
  final _state = _DormitoryInfoControllerState(
    selectCityValue: _selectCity,
    selectDistrictValue: _selectDistrict,
    selectAdminTypeValue: _selectAdminType,
    adminTypes: const <String>[_publicAdminType, _privateAdminType],
  );

  @override
  void onInit() {
    super.onInit();
    _initializeDormitoryInfoController();
  }

  @override
  void onClose() {
    _disposeDormitoryInfoController();
    super.onClose();
  }
}
