part of 'scholarship_applications_list_controller.dart';

ScholarshipApplicationsListController
    ensureScholarshipApplicationsListController({
  required String tag,
  required String docID,
  required List<String> basvuranlar,
  bool permanent = false,
}) {
  final existing = maybeFindScholarshipApplicationsListController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    ScholarshipApplicationsListController(
      docID: docID,
      basvuranlar: basvuranlar,
    ),
    tag: tag,
    permanent: permanent,
  );
}

ScholarshipApplicationsListController?
    maybeFindScholarshipApplicationsListController({
  required String tag,
}) {
  final isRegistered =
      Get.isRegistered<ScholarshipApplicationsListController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<ScholarshipApplicationsListController>(tag: tag);
}

extension ScholarshipApplicationsListControllerFacadePart
    on ScholarshipApplicationsListController {
  Future<void> onRefresh() async {
    isRefreshing.value = true;
    await Future.delayed(const Duration(milliseconds: 500));
    isRefreshing.value = false;
  }
}
