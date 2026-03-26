part of 'tests_grid_controller.dart';

class TestsGridController extends GetxController {
  static TestsGridController ensure(
    TestsModel model, {
    Function? onUpdate,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      TestsGridController(model, onUpdate),
      tag: tag,
      permanent: permanent,
    );
  }

  static TestsGridController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<TestsGridController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<TestsGridController>(tag: tag);
  }

  final TestsModel model;
  final Function? onUpdate;
  final _state = _TestsGridControllerState();

  TestsGridController(this.model, this.onUpdate) {
    _initializeTestsGridController(this);
  }
}
