part of 'family_info_controller.dart';

FamilyInfoController _ensureFamilyInfoController({
  required String tag,
  bool permanent = false,
}) =>
    _maybeFindFamilyInfoController(tag: tag) ??
    Get.put(FamilyInfoController(), tag: tag, permanent: permanent);

FamilyInfoController? _maybeFindFamilyInfoController({required String tag}) =>
    Get.isRegistered<FamilyInfoController>(tag: tag)
        ? Get.find<FamilyInfoController>(tag: tag)
        : null;

void _handleFamilyInfoControllerInit(FamilyInfoController controller) {
  controller._handleOnInit();
}
