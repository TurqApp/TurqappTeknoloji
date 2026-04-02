part of 'prefetch_scheduler.dart';

const String _prefetchSchedulerCdnOrigin = 'https://cdn.turqapp.com';
const Map<String, String> _prefetchSchedulerCdnHeaders = {
  'X-Turq-App': 'turqapp-mobile',
  'Referer': '$_prefetchSchedulerCdnOrigin/',
};
const int _prefetchSchedulerTargetReadySegments = 2;
const int _prefetchSchedulerFallbackFeedFullWindow = 15;
const int _prefetchSchedulerFallbackFeedPrepWindow = 8;
const int _prefetchSchedulerWifiMinBreadthCount = 12;
const int _prefetchSchedulerWifiMinDepthCount = 7;
const int _prefetchSchedulerWifiMinMaxConcurrent = 4;
const int _prefetchSchedulerWifiMinFeedFullWindow = 15;
const int _prefetchSchedulerWifiMinFeedPrepWindow = 20;
const double _prefetchSchedulerWifiQuotaFillRatio = 0.70;
const int _prefetchSchedulerFeedBankMaxDocs = 200;

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
bool shouldUsePrefetchQuotaFillMode({
  required bool isOnWiFi,
  required bool mobileSeedMode,
  required double watchProgress,
}) {
  return isOnWiFi && !mobileSeedMode && watchProgress <= 0.01;
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
  for (var index = 0; index < normalizedDesired; index++) {
    if (!cachedSegmentIndices.contains(index)) {
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
  int maxDocs = _prefetchSchedulerFeedBankMaxDocs,
}) {
  if (posts.isEmpty || maxDocs <= 0) {
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
    if (docIds.length >= maxDocs) break;
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
  int maxDocs = _prefetchSchedulerFeedBankMaxDocs,
}) {
  if (maxDocs <= 0) {
    return const <String>[];
  }

  final merged = <String>[];
  final seen = <String>{};
  for (final docId in incomingDocIds.followedBy(existingDocIds)) {
    final trimmed = docId.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) continue;
    merged.add(trimmed);
    if (merged.length >= maxDocs) break;
  }
  return merged;
}
