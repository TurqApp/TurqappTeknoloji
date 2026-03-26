part of 'application_review_controller_library.dart';

class ApplicationReviewController extends GetxController {
  final _ApplicationReviewControllerState _state;

  ApplicationReviewController({required String jobDocID})
      : _state = _ApplicationReviewControllerState(jobDocID: jobDocID);

  @override
  void onInit() {
    super.onInit();
    unawaited(_handleOnInit());
  }
}

ApplicationReviewController ensureApplicationReviewController({
  required String jobDocID,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindApplicationReviewController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    ApplicationReviewController(jobDocID: jobDocID),
    tag: tag,
    permanent: permanent,
  );
}

ApplicationReviewController? maybeFindApplicationReviewController({
  String? tag,
}) {
  final isRegistered = Get.isRegistered<ApplicationReviewController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<ApplicationReviewController>(tag: tag);
}
