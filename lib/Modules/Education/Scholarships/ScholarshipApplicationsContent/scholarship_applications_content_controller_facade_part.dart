part of 'scholarship_applications_content_controller.dart';

ScholarshipApplicationsContentController
    ensureScholarshipApplicationsContentController({
  required String tag,
  required String userID,
  bool permanent = false,
}) {
  final existing = maybeFindScholarshipApplicationsContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    ScholarshipApplicationsContentController(userID: userID),
    tag: tag,
    permanent: permanent,
  );
}

ScholarshipApplicationsContentController?
    maybeFindScholarshipApplicationsContentController({
  required String tag,
}) {
  final isRegistered =
      Get.isRegistered<ScholarshipApplicationsContentController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<ScholarshipApplicationsContentController>(tag: tag);
}
