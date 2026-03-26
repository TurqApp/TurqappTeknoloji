part of 'my_tutoring_applications_controller.dart';

class MyTutoringApplicationsController extends GetxController {
  static MyTutoringApplicationsController ensure({
    String? tag,
    bool permanent = false,
  }) =>
      maybeFind(tag: tag) ??
      Get.put(
        MyTutoringApplicationsController(),
        tag: tag,
        permanent: permanent,
      );

  static MyTutoringApplicationsController? maybeFind({String? tag}) =>
      Get.isRegistered<MyTutoringApplicationsController>(tag: tag)
          ? Get.find<MyTutoringApplicationsController>(tag: tag)
          : null;

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _MyTutoringApplicationsControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleInit();
  }
}
