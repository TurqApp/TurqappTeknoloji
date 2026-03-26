part of 'my_applications_controller.dart';

MyApplicationsController ensureMyApplicationsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindMyApplicationsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    MyApplicationsController(),
    tag: tag,
    permanent: permanent,
  );
}

MyApplicationsController? maybeFindMyApplicationsController({String? tag}) {
  final isRegistered = Get.isRegistered<MyApplicationsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<MyApplicationsController>(tag: tag);
}
