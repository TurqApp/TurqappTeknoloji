part of 'cv_controller.dart';

CvController ensureCvController({String? tag, bool permanent = false}) =>
    _ensureCvController(tag: tag, permanent: permanent);

CvController? maybeFindCvController({String? tag}) =>
    _maybeFindCvController(tag: tag);

CvController _ensureCvController({
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindCvController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    CvController(),
    tag: tag,
    permanent: permanent,
  );
}

CvController? _maybeFindCvController({String? tag}) {
  final isRegistered = Get.isRegistered<CvController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<CvController>(tag: tag);
}

void _handleCvControllerInit(CvController controller) {
  controller._seedFromCurrentUser();
  controller.ensureDefaultPhoto();
  unawaited(controller._bootstrapCvData());
}

void _handleCvControllerClose(CvController controller) {
  controller.firstName.dispose();
  controller.lastName.dispose();
  controller.mail.dispose();
  controller.phoneNumber.dispose();
  controller.linkedin.dispose();
  controller.onYazi.dispose();
}
