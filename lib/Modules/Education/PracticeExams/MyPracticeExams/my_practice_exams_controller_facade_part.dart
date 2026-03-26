part of 'my_practice_exams_controller.dart';

MyPracticeExamsController? maybeFindMyPracticeExamsController() {
  final isRegistered = Get.isRegistered<MyPracticeExamsController>();
  if (!isRegistered) return null;
  return Get.find<MyPracticeExamsController>();
}

MyPracticeExamsController ensureMyPracticeExamsController({
  bool permanent = false,
}) {
  final existing = maybeFindMyPracticeExamsController();
  if (existing != null) return existing;
  return Get.put(MyPracticeExamsController(), permanent: permanent);
}
