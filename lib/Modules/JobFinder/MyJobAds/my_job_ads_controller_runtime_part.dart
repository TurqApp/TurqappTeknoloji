part of 'my_job_ads_controller_library.dart';

extension MyJobAdsControllerRuntimePart on MyJobAdsController {
  bool _sameJobEntries(List<JobModel> current, List<JobModel> next) {
    final currentKeys = current
        .map(
          (job) => [
            job.docID,
            job.logo,
            job.brand,
            job.meslek,
            job.ilanBasligi,
            job.city,
            job.town,
            job.timeStamp,
            job.viewCount,
            job.applicationCount,
            job.ended,
            job.calismaTuru.join('|'),
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (job) => [
            job.docID,
            job.logo,
            job.brand,
            job.meslek,
            job.ilanBasligi,
            job.city,
            job.town,
            job.timeStamp,
            job.viewCount,
            job.applicationCount,
            job.ended,
            job.calismaTuru.join('|'),
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  void _handleOnInit() {
    unawaited(_bootstrapImpl());
  }

  Future<void> getActive({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _getActiveImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<void> getDeactive({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _getDeactiveImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleOnClose() {
    pageController.dispose();
  }
}
