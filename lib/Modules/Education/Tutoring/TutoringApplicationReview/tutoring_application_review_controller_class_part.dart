part of 'tutoring_application_review_controller.dart';

class TutoringApplicationReviewController extends GetxController {
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
