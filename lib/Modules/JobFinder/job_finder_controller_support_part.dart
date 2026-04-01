part of 'job_finder_controller.dart';

const int _jobFinderFullBootstrapLimit = ReadBudgetRegistry.jobHomeInitialLimit;
const String _jobFinderListingSelectionPrefKeyPrefix =
    'pasaj_job_listing_selection';
const String _jobFinderAllTurkeyRaw = 'Tüm Türkiye';

extension JobFinderControllerSupportPart on JobFinderController {
  void primePrimarySurfaceOnce() {
    if (_primarySurfacePrimedOnce) return;
    _primarySurfacePrimedOnce = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      unawaited(onPrimarySurfaceVisible());
    });
  }

  Future<void> onPrimarySurfaceVisible() => prepareStartupSurface();

  Future<void> prepareStartupSurface({bool? allowBackgroundRefresh}) =>
      _performPrepareStartupSurface(
        allowBackgroundRefresh: allowBackgroundRefresh,
      );

  List<String> get innerTabTitles => [
        'pasaj.job_finder.tab.explore'.tr,
        'pasaj.job_finder.tab.create'.tr,
        'pasaj.job_finder.tab.applications'.tr,
        'pasaj.job_finder.tab.career_profile'.tr,
      ];

  String get _allTurkeyLabel => 'pasaj.common.all_turkiye'.tr;

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
            job.kacKm.toStringAsFixed(2),
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
            job.kacKm.toStringAsFixed(2),
            job.calismaTuru.join('|'),
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  bool _sameJobList(List<JobModel> next) => _sameJobEntries(list, next);

  bool isAllTurkeySelection(String value) =>
      value.trim().isEmpty ||
      value == _jobFinderAllTurkeyRaw ||
      value == _allTurkeyLabel;

  String _listingSelectionKeyFor(String uid) =>
      '${_jobFinderListingSelectionPrefKeyPrefix}_$uid';

  void onInnerTabTap(int index) {
    innerTabIndex.value = index;
    innerPageController.jumpToPage(index);
  }

  void onInnerPageChanged(int index) {
    innerTabIndex.value = index;
  }

  void toggleListingSelection() {
    listingSelection.value = listingSelection.value == 0 ? 1 : 0;
    unawaited(_persistListingSelection());
  }

  Future<void> refreshJob(String docID) async {
    try {
      final updatedJob = await _jobRepository.fetchById(
        docID,
        preferCache: false,
        forceRefresh: true,
      );
      if (updatedJob != null) {
        final index = list.indexWhere((e) => e.docID == docID);
        if (index != -1) {
          list[index] = _attachDistance(updatedJob);
          list.refresh();
        }
      }
    } catch (_) {}
  }
}
