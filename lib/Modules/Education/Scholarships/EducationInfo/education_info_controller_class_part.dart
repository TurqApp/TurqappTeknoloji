part of 'education_info_controller.dart';

class EducationInfoController extends GetxController
    with GetTickerProviderStateMixin {
  static EducationInfoController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(EducationInfoController(), tag: tag, permanent: permanent);
  }

  static EducationInfoController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<EducationInfoController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<EducationInfoController>(tag: tag);
  }

  static const String _middleSchool = 'Ortaokul';
  static const String _highSchool = 'Lise';
  static const String _associate = 'Önlisans';
  static const String _bachelor = 'Lisans';
  static const String _masters = 'Yüksek Lisans';
  static const String _doctorate = 'Doktora';
  final UserRepository _userRepository = UserRepository.ensure();
  final CurrentUserService _currentUserService = CurrentUserService.instance;
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final EducationReferenceDataService _referenceDataService =
      EducationReferenceDataService.ensure();
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
