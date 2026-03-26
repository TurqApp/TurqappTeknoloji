part of 'my_test_results_controller.dart';

class MyTestResultsController extends GetxController {
  static MyTestResultsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyTestResultsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyTestResultsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MyTestResultsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyTestResultsController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final list = <TestsModel>[].obs;
  final isLoading = true.obs;
  final TestRepository _testRepository = TestRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    handleRuntimeInit();
  }
}
