part of 'application_review_controller.dart';

class ApplicationReviewController extends GetxController {
  final _ApplicationReviewControllerState _state;
  static const Duration _silentRefreshInterval = Duration(minutes: 3);
  static const int _maxCacheSize = 50;

  ApplicationReviewController({required String jobDocID})
      : _state = _ApplicationReviewControllerState(jobDocID: jobDocID);

  @override
  void onInit() {
    super.onInit();
    unawaited(_handleOnInit());
  }
}
