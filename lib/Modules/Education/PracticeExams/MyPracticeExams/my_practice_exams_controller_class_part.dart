part of 'my_practice_exams_controller.dart';

class MyPracticeExamsController extends GetxController {
  final PracticeExamRepository _practiceExamRepository =
      ensurePracticeExamRepository();

  final RxList<SinavModel> exams = <SinavModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapExamsImpl());
  }
}
