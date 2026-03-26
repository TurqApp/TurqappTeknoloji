part of 'tests_grid_controller.dart';

class TestsGridController extends GetxController {
  static TestsGridController ensure(
    TestsModel model, {
    Function? onUpdate,
    String? tag,
    bool permanent = false,
  }) =>
      maybeFind(tag: tag) ??
      Get.put(
        TestsGridController(model, onUpdate),
        tag: tag,
        permanent: permanent,
      );

  static TestsGridController? maybeFind({String? tag}) =>
      Get.isRegistered<TestsGridController>(tag: tag)
          ? Get.find<TestsGridController>(tag: tag)
          : null;

  final TestsModel model;
  final Function? onUpdate;
  final _state = _TestsGridControllerState();

  TestsGridController(this.model, this.onUpdate) {
    _initializeTestsGridController(this);
  }
}
