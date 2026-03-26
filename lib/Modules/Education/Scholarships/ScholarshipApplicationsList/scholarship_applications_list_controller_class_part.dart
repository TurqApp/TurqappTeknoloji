part of 'scholarship_applications_list_controller.dart';

class ScholarshipApplicationsListController extends GetxController {
  static ScholarshipApplicationsListController ensure({
    required String tag,
    required String docID,
    required List<String> basvuranlar,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
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

  static ScholarshipApplicationsListController? maybeFind({
    required String tag,
  }) {
    final isRegistered =
        Get.isRegistered<ScholarshipApplicationsListController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ScholarshipApplicationsListController>(tag: tag);
  }

  final String docID;
  final List<String> basvuranlar;

  ScholarshipApplicationsListController({
    required this.docID,
    required this.basvuranlar,
  });

  var isRefreshing = false.obs;

  Future<void> onRefresh() async {
    isRefreshing.value = true;
    await Future.delayed(const Duration(milliseconds: 500));
    isRefreshing.value = false;
  }
}
