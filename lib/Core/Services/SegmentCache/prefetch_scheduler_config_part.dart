part of 'prefetch_scheduler.dart';

const String _prefetchSchedulerCdnOrigin = 'https://cdn.turqapp.com';
const Map<String, String> _prefetchSchedulerCdnHeaders = {
  'X-Turq-App': 'turqapp-mobile',
  'Referer': '$_prefetchSchedulerCdnOrigin/',
};
const int _prefetchSchedulerTargetReadySegments = 2;
const int _prefetchSchedulerPriorityWindowSize = 5;
const int _prefetchSchedulerPriorityPromotionOffset = 2;
const int _prefetchSchedulerFallbackFeedFullWindow = 15;
const int _prefetchSchedulerFallbackFeedPrepWindow = 8;
const int _prefetchSchedulerWifiMinBreadthCount = 12;
const int _prefetchSchedulerWifiMinDepthCount = 7;
const int _prefetchSchedulerWifiMinMaxConcurrent = 4;
const int _prefetchSchedulerWifiMinFeedFullWindow = 15;
const int _prefetchSchedulerWifiMinFeedPrepWindow = 20;
const int _prefetchSchedulerFeedBankBatchSize = 20;
const int _prefetchSchedulerQuotaFillBurstSegments = 2;
const int _prefetchSchedulerQuotaFillBoostReadySegments = 8;
const int _prefetchSchedulerQuotaFillRemotePageLimit = 40;
const int _prefetchSchedulerQuotaFillPlanningDocLimit = 180;
const int _prefetchSchedulerQuotaFillLowWatermark = 8;

@visibleForTesting
int resolvePrefetchReadySegmentsForPost(
  PostsModel? post, {
  int fallbackReadySegments = _prefetchSchedulerTargetReadySegments,
}) {
  final normalizedFallback =
      fallbackReadySegments < 1 ? 1 : fallbackReadySegments;
  if (post?.isFloodSeriesContent ?? false) {
    return 1;
  }
  return normalizedFallback;
}

@visibleForTesting
bool isPriorityWindowTargetIndex({
  required int currentIndex,
  required int targetIndex,
}) {
  final batchStart = (currentIndex ~/ _prefetchSchedulerPriorityWindowSize) *
      _prefetchSchedulerPriorityWindowSize;
  final currentBatchEnd = batchStart + _prefetchSchedulerPriorityWindowSize;
  final nextBatchStart = currentBatchEnd;
  final nextBatchEnd = nextBatchStart + _prefetchSchedulerPriorityWindowSize;

  final isInCurrentBatch =
      targetIndex >= batchStart && targetIndex < currentBatchEnd;
  if (isInCurrentBatch) {
    return true;
  }

  final shouldPromoteNextBatch =
      currentIndex >= batchStart + _prefetchSchedulerPriorityPromotionOffset;
  final isInNextBatch =
      targetIndex >= nextBatchStart && targetIndex < nextBatchEnd;
  if (shouldPromoteNextBatch && isInNextBatch) {
    return true;
  }

  return false;
}

@visibleForTesting
bool shouldUsePrefetchQuotaFillMode({
  required bool isOnWiFi,
  required bool mobileSeedMode,
  required double watchProgress,
}) {
  return isOnWiFi && !mobileSeedMode && watchProgress <= 0.01;
}

@visibleForTesting
bool shouldUseStartupBurstPrefetch({
  required bool isFocusedDoc,
  required bool isCurrentDoc,
  required double watchProgress,
  required int cachedSegmentCount,
  required int desiredReadySegments,
  required int totalSegments,
}) {
  if ((!isFocusedDoc && !isCurrentDoc) ||
      desiredReadySegments < 2 ||
      totalSegments < 2 ||
      cachedSegmentCount >= desiredReadySegments) {
    return false;
  }
  final currentSegment = HlsSegmentPolicy.estimateCurrentSegmentFromProgress(
    progress: watchProgress,
    totalSegments: totalSegments,
  );
  return currentSegment <= 1;
}

@visibleForTesting
List<int> buildQuotaFillSegmentOrder({
  required int totalSegments,
  required int desiredReadySegments,
  Set<int> cachedSegmentIndices = const <int>{},
}) {
  if (totalSegments <= 0) {
    return const <int>[];
  }
  final normalizedDesired = desiredReadySegments < 1
      ? 1
      : (desiredReadySegments > totalSegments
          ? totalSegments
          : desiredReadySegments);
  final ordered = <int>[];
  final seen = <int>{};
  for (var index = 0; index < normalizedDesired; index++) {
    if (seen.add(index) && !cachedSegmentIndices.contains(index)) {
      ordered.add(index);
    }
  }
  for (var index = normalizedDesired; index < totalSegments; index++) {
    if (seen.add(index) && !cachedSegmentIndices.contains(index)) {
      ordered.add(index);
    }
  }
  return ordered;
}

@visibleForTesting
List<String> buildFeedBankDocIds({
  required List<PostsModel> posts,
  required int currentIndex,
  int unseenHeadWindow = ReadBudgetRegistry.feedReadyForNavCount,
  int? maxDocs,
}) {
  if (posts.isEmpty) {
    return const <String>[];
  }

  final safeCurrent = currentIndex.clamp(0, posts.length - 1);
  final startIndex = (safeCurrent + unseenHeadWindow).clamp(0, posts.length);
  final docIds = <String>[];
  final seen = <String>{};
  for (final post in posts.skip(startIndex)) {
    final docId = post.docID.trim();
    if (docId.isEmpty || !seen.add(docId)) continue;
    if (!post.hasPlayableVideo) continue;
    if (normalizeRozetValue(post.rozet).isEmpty) continue;
    docIds.add(docId);
    if (maxDocs != null && maxDocs > 0 && docIds.length >= maxDocs) {
      break;
    }
  }
  return docIds;
}

@visibleForTesting
List<String> pruneSeenFeedBankDocIds({
  required List<String> bankDocIds,
  required List<PostsModel> posts,
  required int currentIndex,
  int seenHeadWindow = ReadBudgetRegistry.feedReadyForNavCount,
}) {
  if (bankDocIds.isEmpty || posts.isEmpty) {
    return bankDocIds;
  }

  final safeCurrent = currentIndex.clamp(0, posts.length - 1);
  final seenUntil = (safeCurrent + seenHeadWindow).clamp(0, posts.length);
  final seenIds = posts
      .take(seenUntil)
      .map((post) => post.docID.trim())
      .where((docId) => docId.isNotEmpty)
      .toSet();
  if (seenIds.isEmpty) return bankDocIds;
  return bankDocIds
      .where((docId) => !seenIds.contains(docId.trim()))
      .toList(growable: false);
}

@visibleForTesting
List<String> mergeFeedBankDocIds({
  required List<String> existingDocIds,
  required List<String> incomingDocIds,
  int? maxDocs,
}) {
  final merged = <String>[];
  final seen = <String>{};
  for (final docId in incomingDocIds.followedBy(existingDocIds)) {
    final trimmed = docId.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) continue;
    merged.add(trimmed);
    if (maxDocs != null && maxDocs > 0 && merged.length >= maxDocs) {
      break;
    }
  }
  return merged;
}
