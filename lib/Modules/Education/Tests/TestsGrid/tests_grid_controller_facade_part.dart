part of 'tests_grid_controller.dart';

TestsGridController ensureTestsGridController(
  TestsModel model, {
  Function? onUpdate,
  String? tag,
  bool permanent = false,
}) =>
    maybeFindTestsGridController(tag: tag) ??
    Get.put(
      TestsGridController(model, onUpdate),
      tag: tag,
      permanent: permanent,
    );

TestsGridController? maybeFindTestsGridController({String? tag}) =>
    Get.isRegistered<TestsGridController>(tag: tag)
        ? Get.find<TestsGridController>(tag: tag)
        : null;
