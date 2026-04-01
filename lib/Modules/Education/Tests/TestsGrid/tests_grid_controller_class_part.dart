part of 'tests_grid_controller.dart';

class TestsGridController extends GetxController {
  final TestsModel model;
  final Function? onUpdate;
  final _state = _TestsGridControllerState();

  TestsGridController(this.model, this.onUpdate) {
    _initializeTestsGridController(this);
  }
}
