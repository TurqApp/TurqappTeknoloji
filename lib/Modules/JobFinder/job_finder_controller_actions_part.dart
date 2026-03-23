part of 'job_finder_controller.dart';

extension JobFinderControllerActionsPart on JobFinderController {
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
