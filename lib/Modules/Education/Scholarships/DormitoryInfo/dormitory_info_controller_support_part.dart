part of 'dormitory_info_controller.dart';

extension DormitoryInfoControllerSupportPart on DormitoryInfoController {
  String get selectCityValue => DormitoryInfoController._selectCity;
  String get selectDistrictValue => DormitoryInfoController._selectDistrict;
  String get selectAdminTypeValue => DormitoryInfoController._selectAdminType;

  bool get isCityUnselected =>
      sehir.value.isEmpty || sehir.value == DormitoryInfoController._selectCity;

  void _initializeDormitoryInfoController() {
    _loadInitialData();
    ever(yurt, (_) {
      yurtSelectionController.text = yurt.value;
    });
    yurtInput.addListener(() {
      yurtInputText.value = yurtInput.text;
    });
  }

  void _disposeDormitoryInfoController() {
    yurtInput.dispose();
    yurtSelectionController.dispose();
  }
}
