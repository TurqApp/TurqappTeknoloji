part of 'dormitory_info_controller.dart';

abstract class _DormitoryInfoControllerBase extends GetxController {
  final _state = _DormitoryInfoControllerState(
    selectCityValue: DormitoryInfoController._selectCity,
    selectDistrictValue: DormitoryInfoController._selectDistrict,
    selectAdminTypeValue: DormitoryInfoController._selectAdminType,
    adminTypes: const <String>[
      DormitoryInfoController._publicAdminType,
      DormitoryInfoController._privateAdminType,
    ],
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
