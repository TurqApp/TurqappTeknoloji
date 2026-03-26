part of 'applications_controller_library.dart';

ApplicationsController ensureApplicationsController({
  required String tag,
  bool permanent = false,
}) =>
    maybeFindApplicationsController(tag: tag) ??
    Get.put(ApplicationsController(), tag: tag, permanent: permanent);

ApplicationsController? maybeFindApplicationsController({required String tag}) {
  if (!Get.isRegistered<ApplicationsController>(tag: tag)) return null;
  return Get.find<ApplicationsController>(tag: tag);
}
