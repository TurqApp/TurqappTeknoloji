part of 'deneme_turleri_listesi_controller.dart';

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
