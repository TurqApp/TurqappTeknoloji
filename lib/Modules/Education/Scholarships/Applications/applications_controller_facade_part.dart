part of 'applications_controller_library.dart';

ApplicationsController ensureApplicationsController(
  String tag, {
  bool permanent = false,
}) =>
    maybeFindApplicationsController(tag) ??
    Get.put(ApplicationsController(), tag: tag, permanent: permanent);

ApplicationsController? maybeFindApplicationsController(String tag) =>
    Get.isRegistered<ApplicationsController>(tag: tag)
        ? Get.find<ApplicationsController>(tag: tag)
        : null;
