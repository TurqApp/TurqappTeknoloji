import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'cache_manager.dart';
import 'cache_metrics.dart';
import 'prefetch_scheduler.dart';

/// Debug-only segment cache metrics overlay.
/// Sadece kDebugMode'da gösterilir. Tıkla → genişlet/daralt.
class CacheDebugOverlay extends StatefulWidget {
  const CacheDebugOverlay({super.key});

  @override
  State<CacheDebugOverlay> createState() => _CacheDebugOverlayState();
}

class _CacheDebugOverlayState extends State<CacheDebugOverlay> {
  Timer? _refreshTimer;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  SegmentCacheManager? get _cache {
    try {
      return Get.find<SegmentCacheManager>();
    } catch (_) {
      return null;
    }
  }

  PrefetchScheduler? get _prefetch {
    try {
      return Get.find<PrefetchScheduler>();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final cache = _cache;
    if (cache == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
        ),
        child: _expanded
            ? _buildExpanded(cache.metrics, cache)
            : _buildCompact(cache.metrics),
      ),
    );
  }

  Widget _buildCompact(CacheMetrics metrics) {
    final hitRate = metrics.proxyRequestsTotal > 0
        ? (metrics.cacheHitRate * 100).toStringAsFixed(0)
        : '--';
    return Text(
      'Cache $hitRate%',
      style: const TextStyle(
        color: Colors.green,
        fontSize: 10,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildExpanded(CacheMetrics metrics, SegmentCacheManager cache) {
    final prefetch = _prefetch;
    final soft = cache.softLimitBytes;
    final hard = cache.hardLimitBytes;
    final used = cache.totalSizeBytes;
    final usagePct = hard > 0 ? ((used / hard) * 100).clamp(0, 999) : 0;
    final softPct = hard > 0 ? ((soft / hard) * 100).clamp(0, 999) : 0;

    final lines = <String>[
      'segment_cache.hit_miss'
          .trParams({'hits': '${metrics.cacheHits}', 'misses': '${metrics.cacheMisses}'}),
      'segment_cache.rate'
          .trParams({'rate': (metrics.cacheHitRate * 100).toStringAsFixed(1)}),
      'segment_cache.served'.trParams(
          {'bytes': CacheMetrics.formatBytes(metrics.bytesServedFromCache)}),
      'segment_cache.downloaded'.trParams(
          {'bytes': CacheMetrics.formatBytes(metrics.bytesDownloaded)}),
      'segment_cache.evictions'
          .trParams({'count': '${metrics.evictions}'}),
      'segment_cache.entries'.trParams({'count': '${cache.entryCount}'}),
      'segment_cache.disk'
          .trParams({'bytes': CacheMetrics.formatBytes(cache.totalSizeBytes)}),
      'segment_cache.soft'.trParams({
        'bytes': CacheMetrics.formatBytes(soft),
        'pct': softPct.toStringAsFixed(0),
      }),
      'segment_cache.hard'
          .trParams({'bytes': CacheMetrics.formatBytes(hard)}),
      'segment_cache.usage'
          .trParams({'pct': usagePct.toStringAsFixed(1)}),
      if (prefetch != null) ...[
        'segment_cache.prefetch'.trParams({
          'status': prefetch.isPaused
              ? 'segment_cache.status_paused'.tr
              : 'segment_cache.status_active'.tr,
        }),
        'segment_cache.queue'.trParams({
          'queue': '${prefetch.queueSize}',
          'downloads': '${prefetch.activeDownloads}',
        }),
        'segment_cache.ready'.trParams({
          'ready': '${prefetch.feedReadyCount}',
          'window': '${prefetch.feedWindowCount}',
          'pct': (prefetch.feedReadyRatio * 100).toStringAsFixed(0),
        }),
        'segment_cache.latency'.trParams({
          'ms': prefetch.avgQueueDispatchLatencyMs.toStringAsFixed(0),
        }),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'segment_cache.title'.tr,
          style: TextStyle(
            color: Colors.green,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        ...lines.map((line) => Text(
              line,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontFamily: 'monospace',
              ),
            )),
      ],
    );
  }
}
