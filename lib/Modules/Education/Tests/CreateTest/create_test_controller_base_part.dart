part of 'create_test_controller.dart';

abstract class _CreateTestControllerBase extends GetxController {
  _CreateTestControllerBase(this.model);

  final TestsModel? model;
  final _state = _CreateTestControllerState();
  final TestRepository _testRepository = ensureTestRepository();

  @override
  void onInit() {
    super.onInit();
    (this as CreateTestController).initializeData();
  }

  @override
  void onClose() {
    _state.aciklama.dispose();
    super.onClose();
  }
}
