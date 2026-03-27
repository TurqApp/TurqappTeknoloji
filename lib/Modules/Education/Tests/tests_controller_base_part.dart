part of 'tests_controller_library.dart';

abstract class _TestsControllerBase extends GetxController {
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

class TestsController extends _TestsControllerBase {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  static const int _pageSize = 30;
}

TestsController ensureTestsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindTestsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    TestsController(),
    tag: tag,
    permanent: permanent,
  );
}

TestsController? maybeFindTestsController({String? tag}) {
  final isRegistered = Get.isRegistered<TestsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<TestsController>(tag: tag);
}
