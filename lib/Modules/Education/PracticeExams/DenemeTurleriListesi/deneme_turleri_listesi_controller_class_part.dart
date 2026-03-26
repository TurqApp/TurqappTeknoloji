part of 'deneme_turleri_listesi_controller.dart';

class DenemeTurleriListesiController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  var list = <SinavModel>[].obs;
  var isLoading = false.obs;
  var isInitialized = false.obs;

  final String sinavTuru;
  final PracticeExamRepository _practiceExamRepository =
      ensurePracticeExamRepository();

  DenemeTurleriListesiController({required this.sinavTuru});

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapDataImpl());
  }
}
