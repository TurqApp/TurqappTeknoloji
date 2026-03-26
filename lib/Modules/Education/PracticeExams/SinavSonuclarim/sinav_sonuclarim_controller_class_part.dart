part of 'sinav_sonuclarim_controller.dart';

class SinavSonuclarimController extends GetxController {
  static SinavSonuclarimController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(SinavSonuclarimController(), permanent: permanent);
  }

  static SinavSonuclarimController? maybeFind() {
    final isRegistered = Get.isRegistered<SinavSonuclarimController>();
    if (!isRegistered) return null;
    return Get.find<SinavSonuclarimController>();
  }

  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  var list = <SinavModel>[].obs;
  var ustBar = true.obs;
  var isLoading = true.obs;
  final ScrollController scrollController = ScrollController();
  double _previousOffset = 0.0;

  @override
  void onInit() {
    super.onInit();
    scrolControlcu();
    unawaited(_SinavSonuclarimControllerRuntimeX(this).bootstrapData());
  }

  void scrolControlcu() =>
      _SinavSonuclarimControllerRuntimeX(this).setupScrollController();

  Future<void> findAndGetSinavlar({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _SinavSonuclarimControllerRuntimeX(this).findAndGetSinavlar(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
