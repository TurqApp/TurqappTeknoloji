part of 'job_details_controller.dart';

extension JobDetailsControllerLifecyclePart on JobDetailsController {
  void _handleOnInit() {
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    unawaited(refreshJob());
    unawaited(cvCheck());
    unawaited(getUserData(model.value.userID));
    unawaited(checkSaved(model.value.docID));
    unawaited(checkBasvuru(model.value.docID));
    unawaited(bootstrapSimilar());
    unawaited(bootstrapReviews());
    unawaited(incrementViewCount());
  }
}
