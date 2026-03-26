part of 'tutoring_application_review_controller.dart';

class TutoringApplicationReviewController extends GetxController {
  final _state;

  TutoringApplicationReviewController({required String tutoringDocID})
      : _state = _buildTutoringApplicationReviewState(tutoringDocID);

  @override
  void onInit() {
    super.onInit();
    loadApplicants();
  }
}

TutoringApplicationReviewController ensureTutoringApplicationReviewController({
  required String tutoringDocID,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindTutoringApplicationReviewController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    TutoringApplicationReviewController(tutoringDocID: tutoringDocID),
    tag: tag,
    permanent: permanent,
  );
}

TutoringApplicationReviewController?
    maybeFindTutoringApplicationReviewController({
  String? tag,
}) {
  final isRegistered =
      Get.isRegistered<TutoringApplicationReviewController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<TutoringApplicationReviewController>(tag: tag);
}

extension TutoringApplicationReviewControllerFacadePart
    on TutoringApplicationReviewController {
  Future<void> loadApplicants() =>
      _TutoringApplicationReviewControllerActionsX(this).loadApplicants();

  Future<Map<String, dynamic>?> getApplicantProfile(String userID) =>
      _TutoringApplicationReviewControllerActionsX(this)
          .getApplicantProfile(userID);

  Future<void> updateStatus(String userID, String newStatus) =>
      _TutoringApplicationReviewControllerActionsX(this)
          .updateStatus(userID, newStatus);
}
