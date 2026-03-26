part of 'dormitory_info_controller.dart';

class DormitoryInfoController extends GetxController {
  static DormitoryInfoController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(DormitoryInfoController(), tag: tag, permanent: permanent);
  }

  static DormitoryInfoController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<DormitoryInfoController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<DormitoryInfoController>(tag: tag);
  }

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
