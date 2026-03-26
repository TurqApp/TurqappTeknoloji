part of 'tests_controller.dart';

class TestsController extends GetxController {
  static TestsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      TestsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static TestsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<TestsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<TestsController>(tag: tag);
  }

  final TestRepository _testRepository = TestRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final list = <TestsModel>[].obs;
  final showButtons = false.obs;
  final ustBar = true.obs;
  final scrollController = ScrollController();
  final _previousOffset = 0.0.obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final RxDouble scrollOffset = 0.0.obs;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 30;

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }

  @override
  void onClose() {
    _handleControllerClose();
    super.onClose();
  }
}
