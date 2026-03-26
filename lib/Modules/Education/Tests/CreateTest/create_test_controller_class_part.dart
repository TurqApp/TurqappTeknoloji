part of 'create_test_controller.dart';

class CreateTestController extends GetxController {
  static CreateTestController ensure(
    TestsModel? model, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CreateTestController(model),
      tag: tag,
      permanent: permanent,
    );
  }

  static CreateTestController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<CreateTestController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CreateTestController>(tag: tag);
  }

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
