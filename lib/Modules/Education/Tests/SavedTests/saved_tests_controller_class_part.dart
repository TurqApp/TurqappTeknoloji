part of 'saved_tests_controller.dart';

class SavedTestsController extends GetxController {
  static SavedTestsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SavedTestsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static SavedTestsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<SavedTestsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SavedTestsController>(tag: tag);
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
