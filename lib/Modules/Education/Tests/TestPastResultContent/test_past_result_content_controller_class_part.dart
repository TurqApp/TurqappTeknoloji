part of 'test_past_result_content_controller.dart';

class TestPastResultContentController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final TestsModel model;
  final count = 0.obs;
  final isLoading = true.obs;
  final timeStamp = 0.obs;
  final TestRepository _testRepository = TestRepository.ensure();

  TestPastResultContentController(this.model);

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }
}
