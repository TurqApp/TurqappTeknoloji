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
    (this as DormitoryInfoController)._initializeDormitoryInfoController();
  }

  @override
  void onClose() {
    (this as DormitoryInfoController)._disposeDormitoryInfoController();
    super.onClose();
  }
}
