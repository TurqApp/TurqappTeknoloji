part of 'my_tutorings_controller.dart';

class MyTutoringsController extends GetxController {
  static MyTutoringsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyTutoringsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyTutoringsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MyTutoringsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyTutoringsController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _MyTutoringsControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleMyTutoringsInit();
  }

  @override
  void onClose() {
    _handleMyTutoringsClose();
    super.onClose();
  }
}
