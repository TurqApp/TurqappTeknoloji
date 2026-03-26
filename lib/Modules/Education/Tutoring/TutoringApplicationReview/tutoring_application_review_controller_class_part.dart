part of 'tutoring_application_review_controller.dart';

class TutoringApplicationReviewController extends GetxController {
  static TutoringApplicationReviewController ensure({
    required String tutoringDocID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      TutoringApplicationReviewController(tutoringDocID: tutoringDocID),
      tag: tag,
      permanent: permanent,
    );
  }

  static TutoringApplicationReviewController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<TutoringApplicationReviewController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<TutoringApplicationReviewController>(tag: tag);
  }

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final TutoringRepository _tutoringRepository = TutoringRepository.ensure();
  final String tutoringDocID;
  final _state = _TutoringApplicationReviewControllerState();

  TutoringApplicationReviewController({required this.tutoringDocID});

  @override
  void onInit() {
    super.onInit();
    loadApplicants();
  }

  Future<void> loadApplicants() =>
      _TutoringApplicationReviewControllerActionsX(this).loadApplicants();

  Future<Map<String, dynamic>?> getApplicantProfile(String userID) =>
      _TutoringApplicationReviewControllerActionsX(this)
          .getApplicantProfile(userID);

  Future<void> updateStatus(String userID, String newStatus) =>
      _TutoringApplicationReviewControllerActionsX(this)
          .updateStatus(userID, newStatus);
}
