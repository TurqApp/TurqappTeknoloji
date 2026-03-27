part of 'deneme_turleri_listesi_controller.dart';

class DenemeTurleriListesiController
    extends _DenemeTurleriListesiControllerBase {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  DenemeTurleriListesiController({required super.sinavTuru});
}

abstract class _DenemeTurleriListesiControllerBase extends GetxController {
  _DenemeTurleriListesiControllerBase({required this.sinavTuru});

  final list = <SinavModel>[].obs;
  final isLoading = false.obs;
  final isInitialized = false.obs;
  final String sinavTuru;
  final PracticeExamRepository _practiceExamRepository =
      ensurePracticeExamRepository();

  @override
  void onInit() {
    super.onInit();
    unawaited((this as DenemeTurleriListesiController)._bootstrapDataImpl());
  }
}
