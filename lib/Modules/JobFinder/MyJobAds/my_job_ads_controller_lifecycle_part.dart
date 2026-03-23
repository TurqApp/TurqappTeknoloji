part of 'my_job_ads_controller.dart';

extension MyJobAdsControllerLifecyclePart on MyJobAdsController {
  void _handleOnInit() {
    unawaited(_bootstrapImpl());
  }

  void _handleOnClose() {
    pageController.dispose();
  }
}
