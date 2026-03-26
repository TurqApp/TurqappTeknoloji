part of 'create_test_controller.dart';

class CreateTestController extends GetxController {
  final TestsModel? model;
  final _state = _CreateTestControllerState();
  final TestRepository _testRepository = TestRepository.ensure();

  CreateTestController(this.model);

  @override
  void onInit() {
    super.onInit();
    initializeData();
  }

  @override
  void onClose() {
    aciklama.dispose();
    super.onClose();
  }
}
