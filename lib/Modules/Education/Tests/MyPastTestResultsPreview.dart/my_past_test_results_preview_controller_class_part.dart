part of 'my_past_test_results_preview_controller.dart';

class MyPastTestResultsPreviewController extends GetxController {
  static MyPastTestResultsPreviewController ensure(
    TestsModel model, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyPastTestResultsPreviewController(model),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyPastTestResultsPreviewController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<MyPastTestResultsPreviewController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyPastTestResultsPreviewController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final TestsModel model;
  final yanitlar = <String>[].obs;
  final timeStamp = 0.obs;
  final soruList = <TestReadinessModel>[].obs;
  final dogruSayisi = 0.obs;
  final yanlisSayisi = 0.obs;
  final bosSayisi = 0.obs;
  final totalPuan = 0.0.obs;
  final isLoading = true.obs;
  final TestRepository _testRepository = TestRepository.ensure();

  MyPastTestResultsPreviewController(this.model);

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }
}
