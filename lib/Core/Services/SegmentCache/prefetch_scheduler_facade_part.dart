part of 'prefetch_scheduler.dart';

PrefetchScheduler? maybeFindPrefetchScheduler() =>
    Get.isRegistered<PrefetchScheduler>()
        ? Get.find<PrefetchScheduler>()
        : null;

PrefetchScheduler ensurePrefetchScheduler({bool permanent = false}) =>
    maybeFindPrefetchScheduler() ??
    Get.put(PrefetchScheduler(), permanent: permanent);

extension PrefetchSchedulerReadFacadePart on PrefetchScheduler {
  List<String> currentFeedDocIds() =>
      List<String>.from(_lastFeedDocIDs, growable: false);

  List<String> currentFeedSurfaceVideoDocIds() =>
      List<String>.from(_lastFeedSurfaceVideoDocIDs, growable: false);

  List<String> currentFeedBankDocIds() =>
      List<String>.from(_lastFeedBankDocIDs, growable: false);

  int queuePositionForDoc(String docID) {
    final normalized = HlsSegmentPolicy.normalizeDocId(docID);
    if (normalized == null || normalized.isEmpty) return -1;
    return _queue.indexWhere((job) => job.docID == normalized);
  }

  bool isActivelyDownloadingDoc(String docID) {
    final normalized = HlsSegmentPolicy.normalizeDocId(docID);
    if (normalized == null || normalized.isEmpty) return false;
    return (_activeDocRefCounts[normalized] ?? 0) > 0;
  }

  bool hasPendingPrefetchForDoc(String docID) {
    final normalized = HlsSegmentPolicy.normalizeDocId(docID);
    if (normalized == null || normalized.isEmpty) return false;
    if (_pendingFollowUpJobs.containsKey(normalized)) return true;
    return _queue.any((job) => job.docID == normalized);
  }
}
