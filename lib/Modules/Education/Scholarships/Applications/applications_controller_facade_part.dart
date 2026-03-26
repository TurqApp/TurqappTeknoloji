part of 'applications_controller.dart';

ApplicationsController ensureApplicationsController({
  required String tag,
  bool permanent = false,
}) =>
    maybeFindApplicationsController(tag: tag) ??
    Get.put(ApplicationsController(), tag: tag, permanent: permanent);

ApplicationsController? maybeFindApplicationsController({
  required String tag,
}) =>
    Get.isRegistered<ApplicationsController>(tag: tag)
        ? Get.find<ApplicationsController>(tag: tag)
        : null;
