part of 'job_details_controller.dart';

extension _JobDetailsControllerRuntimeX on JobDetailsController {
  void handleOnInit() {
    unawaited(initialize());
  }

  Future<void> initialize() async {
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
