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
