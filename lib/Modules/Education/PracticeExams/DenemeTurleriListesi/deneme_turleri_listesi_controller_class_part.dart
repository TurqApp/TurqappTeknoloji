part of 'deneme_turleri_listesi_controller.dart';

class DenemeTurleriListesiController extends GetxController {
  static DenemeTurleriListesiController ensure({
    required String tag,
    required String sinavTuru,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      DenemeTurleriListesiController(sinavTuru: sinavTuru),
      tag: tag,
      permanent: permanent,
    );
  }

  static DenemeTurleriListesiController? maybeFind({required String tag}) {
    final isRegistered =
        Get.isRegistered<DenemeTurleriListesiController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<DenemeTurleriListesiController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  var list = <SinavModel>[].obs;
  var isLoading = false.obs;
  var isInitialized = false.obs;

  final String sinavTuru;
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();

  DenemeTurleriListesiController({required this.sinavTuru});

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapDataImpl());
  }
}
