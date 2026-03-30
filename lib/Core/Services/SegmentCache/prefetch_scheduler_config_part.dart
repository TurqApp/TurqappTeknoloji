part of 'prefetch_scheduler.dart';

const String _prefetchSchedulerCdnOrigin = 'https://cdn.turqapp.com';
const Map<String, String> _prefetchSchedulerCdnHeaders = {
  'X-Turq-App': 'turqapp-mobile',
  'Referer': '$_prefetchSchedulerCdnOrigin/',
};
const int _prefetchSchedulerTargetReadySegments = 2;
const int _prefetchSchedulerFallbackBreadthCount = 5;
const int _prefetchSchedulerFallbackDepthCount = 3;
const int _prefetchSchedulerFallbackMaxConcurrent = 2;
const int _prefetchSchedulerFallbackFeedFullWindow = 15;
const int _prefetchSchedulerFallbackFeedPrepWindow = 8;
const int _prefetchSchedulerWifiMinBreadthCount = 12;
const int _prefetchSchedulerWifiMinDepthCount = 7;
const int _prefetchSchedulerWifiMinMaxConcurrent = 4;
const int _prefetchSchedulerWifiMinFeedFullWindow = 15;
const int _prefetchSchedulerWifiMinFeedPrepWindow = 20;
const double _prefetchSchedulerWifiQuotaFillRatio = 0.70;
