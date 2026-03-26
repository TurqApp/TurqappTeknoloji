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

  final _state;

  TutoringApplicationReviewController({required String tutoringDocID})
      : _state = _TutoringApplicationReviewControllerState(
          tutoringDocID: tutoringDocID,
        );

  @override
  void onInit() {
    super.onInit();
    loadApplicants();
  }
}
