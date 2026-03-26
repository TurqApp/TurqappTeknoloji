part of 'my_tutorings_controller.dart';

MyTutoringsController ensureMyTutoringsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindMyTutoringsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    MyTutoringsController(),
    tag: tag,
    permanent: permanent,
  );
}

MyTutoringsController? maybeFindMyTutoringsController({String? tag}) {
  final isRegistered = Get.isRegistered<MyTutoringsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<MyTutoringsController>(tag: tag);
}
