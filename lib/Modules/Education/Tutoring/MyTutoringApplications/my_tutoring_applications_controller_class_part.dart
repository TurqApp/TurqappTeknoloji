part of 'my_tutoring_applications_controller.dart';

class MyTutoringApplicationsController extends GetxController {
  static MyTutoringApplicationsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyTutoringApplicationsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyTutoringApplicationsController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<MyTutoringApplicationsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyTutoringApplicationsController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _MyTutoringApplicationsControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleInit();
  }
}
