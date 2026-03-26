part of 'personel_info_controller.dart';

class PersonelInfoController extends GetxController
    with GetTickerProviderStateMixin {
  static PersonelInfoController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(PersonelInfoController(), tag: tag, permanent: permanent);
  }

  static PersonelInfoController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<PersonelInfoController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PersonelInfoController>(tag: tag);
  }

  final UserRepository _userRepository = UserRepository.ensure();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final _state = _PersonelInfoControllerState();

  String get defaultSelectValue => _selectValue;
  String get turkeyValue => _turkey;
  String get singleValue => _single;
  String get noneValue => _none;
  String get notWorkingValue => _notWorking;
  bool get isTurkeySelected => county.value == _turkey;

  @override
  void onInit() {
    super.onInit();
    loadCitiesAndTowns();
    fetchData();
    initializeFieldConfigs();
    initializeAnimationControllers();
  }

  @override
  void onClose() {
    disposeAnimationControllers();
    super.onClose();
  }
}
