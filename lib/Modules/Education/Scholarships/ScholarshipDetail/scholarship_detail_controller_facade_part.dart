part of 'scholarship_detail_controller_library.dart';

ScholarshipDetailController ensureScholarshipDetailController({
  bool permanent = false,
}) =>
    _ensureScholarshipDetailController(permanent: permanent);

ScholarshipDetailController? maybeFindScholarshipDetailController() =>
    _maybeFindScholarshipDetailController();

ScholarshipDetailController _ensureScholarshipDetailController({
  bool permanent = false,
}) {
  final existing = _maybeFindScholarshipDetailController();
  if (existing != null) return existing;
  return Get.put(ScholarshipDetailController(), permanent: permanent);
}

ScholarshipDetailController? _maybeFindScholarshipDetailController() {
  final isRegistered = Get.isRegistered<ScholarshipDetailController>();
  if (!isRegistered) return null;
  return Get.find<ScholarshipDetailController>();
}

void _handleScholarshipDetailInit(ScholarshipDetailController controller) {
  controller.checkUserApplicationReadiness(showErrors: false);
  final scholarshipData = Get.arguments as Map<String, dynamic>?;
  if (scholarshipData == null) return;
  final scholarshipId =
      (scholarshipData['docId'] ?? scholarshipData['scholarshipId'] ?? '')
          .toString();
  if (scholarshipId.isNotEmpty) {
    controller._loadFullScholarship(scholarshipId);
  }
  controller.checkIfUserAlreadyApplied(scholarshipData, showErrors: false);
  controller._incrementViewCount(scholarshipData);
}
