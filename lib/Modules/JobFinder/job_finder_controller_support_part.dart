part of 'job_finder_controller.dart';

extension JobFinderControllerSupportPart on JobFinderController {
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
      value == JobFinderController._allTurkeyRaw ||
      value == _allTurkeyLabel;

  String _listingSelectionKeyFor(String uid) =>
      '${JobFinderController._listingSelectionPrefKeyPrefix}_$uid';

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
