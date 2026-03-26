part of 'my_practice_exams_controller_library.dart';

MyPracticeExamsController? maybeFindMyPracticeExamsController() =>
    Get.isRegistered<MyPracticeExamsController>()
        ? Get.find<MyPracticeExamsController>()
        : null;

MyPracticeExamsController ensureMyPracticeExamsController({
  bool permanent = false,
}) =>
    maybeFindMyPracticeExamsController() ??
    Get.put(MyPracticeExamsController(), permanent: permanent);
