part of 'tests_controller.dart';

class TestsController extends GetxController {
  static TestsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      TestsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static TestsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<TestsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<TestsController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  static const int _pageSize = 30;
  final _state = _TestsControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }

  @override
  void onClose() {
    _handleControllerClose();
    super.onClose();
  }
}
