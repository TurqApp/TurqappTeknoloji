part of 'education_info_controller.dart';

EducationInfoController ensureEducationInfoController({
  required String tag,
  bool permanent = false,
}) {
  final existing = maybeFindEducationInfoController(tag: tag);
  if (existing != null) return existing;
  return Get.put(EducationInfoController(), tag: tag, permanent: permanent);
}

EducationInfoController? maybeFindEducationInfoController({
  required String tag,
}) {
  final isRegistered = Get.isRegistered<EducationInfoController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<EducationInfoController>(tag: tag);
}
