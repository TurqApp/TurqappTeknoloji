part of 'my_tests_controller.dart';

class MyTestsController extends GetxController {
  static MyTestsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyTestsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyTestsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MyTestsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyTestsController>(tag: tag);
  }

  final TestRepository _testRepository = ensureTestRepository();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final list = <TestsModel>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    handleRuntimeInit();
  }
}
