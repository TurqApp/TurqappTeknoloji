part of 'my_practice_exams_controller_library.dart';

class MyPracticeExamsController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapExamsImpl());
  }
}
