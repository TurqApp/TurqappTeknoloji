part of 'my_job_ads_controller.dart';

extension MyJobAdsControllerActionsPart on MyJobAdsController {
  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
