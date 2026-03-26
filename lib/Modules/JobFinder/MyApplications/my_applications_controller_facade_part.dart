part of 'my_applications_controller.dart';

const Duration _myApplicationsSilentRefreshInterval = Duration(minutes: 5);

class MyApplicationsController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapApplicationsImpl());
  }
}

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
