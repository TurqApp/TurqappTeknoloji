part of 'tutoring_application_review_controller.dart';

class _TutoringApplicationReviewControllerState {
  final applicants = <TutoringApplicationModel>[].obs;
  final isLoading = false.obs;
}

extension TutoringApplicationReviewControllerFieldsPart
    on TutoringApplicationReviewController {
  RxList<TutoringApplicationModel> get applicants => _state.applicants;
  RxBool get isLoading => _state.isLoading;
}
