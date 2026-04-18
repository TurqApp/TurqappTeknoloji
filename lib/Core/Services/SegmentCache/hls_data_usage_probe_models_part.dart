part of 'hls_data_usage_probe.dart';

class HlsTransferEvent {
  const HlsTransferEvent({
    required this.at,
    required this.docId,
    required this.pathKey,
    required this.source,
    required this.bytes,
    required this.cacheHit,
    required this.visibleDocId,
    required this.variantKey,
    required this.kind,
    required this.networkType,
  });

  final DateTime at;
  final String docId;
  final String pathKey;
  final HlsTrafficSource source;
  final int bytes;
  final bool cacheHit;
  final String? visibleDocId;
  final String? variantKey;
  final String kind;
  final String networkType;

  bool get isVisibleAtTransfer => visibleDocId != null && visibleDocId == docId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'at': at.toIso8601String(),
        'docId': docId,
        'pathKey': pathKey,
        'source': source.name,
        'bytes': bytes,
        'cacheHit': cacheHit,
        'visibleDocId': visibleDocId,
        'variantKey': variantKey,
        'kind': kind,
        'networkType': networkType,
      };
}

class HlsDocUsageSummary {
  const HlsDocUsageSummary({
    required this.docId,
    required this.downloadedBytes,
    required this.cacheServedBytes,
    required this.downloadedSegments,
    required this.repeatedSegmentDownloads,
    required this.playlistDownloads,
    required this.playlistCacheHits,
    required this.variantKeys,
    required this.avgSegmentDurationSec,
    required this.maxSegmentDurationSec,
    required this.minSegmentDurationSec,
    required this.avgSegmentSizeKb,
    required this.maxSegmentSizeKb,
  });

  final String docId;
  final int downloadedBytes;
  final int cacheServedBytes;
  final int downloadedSegments;
  final int repeatedSegmentDownloads;
  final int playlistDownloads;
  final int playlistCacheHits;
  final List<String> variantKeys;
  final double avgSegmentDurationSec;
  final double maxSegmentDurationSec;
  final double minSegmentDurationSec;
  final double avgSegmentSizeKb;
  final double maxSegmentSizeKb;

  double get downloadedMb => downloadedBytes / (1024 * 1024);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'docId': docId,
        'downloadedBytes': downloadedBytes,
        'downloadedMb': downloadedMb,
        'cacheServedBytes': cacheServedBytes,
        'downloadedSegments': downloadedSegments,
        'repeatedSegmentDownloads': repeatedSegmentDownloads,
        'playlistDownloads': playlistDownloads,
        'playlistCacheHits': playlistCacheHits,
        'variantKeys': List<String>.from(variantKeys, growable: false),
        'avgSegmentDurationSec': avgSegmentDurationSec,
        'maxSegmentDurationSec': maxSegmentDurationSec,
        'minSegmentDurationSec': minSegmentDurationSec,
        'avgSegmentSizeKb': avgSegmentSizeKb,
        'maxSegmentSizeKb': maxSegmentSizeKb,
      };
}

class HlsDataUsageSnapshot {
  HlsDataUsageSnapshot({
    required this.label,
    required this.elapsed,
    required this.networkType,
    required this.downloadedBytes,
    required this.cacheServedBytes,
    required this.visibleDownloadedBytes,
    required this.offscreenDownloadedBytes,
    required this.backgroundDownloadedBytes,
    required this.visibleSegmentDownloads,
    required this.backgroundSegmentDownloads,
    required this.prefetchSegmentDownloads,
    required this.prefetchDownloadedBytes,
    required this.playbackDownloadedBytes,
    required this.cellularDownloadedBytes,
    required this.cellularBackgroundDownloadedBytes,
    required this.cellularBackgroundSegmentDownloads,
    required this.cellularPrefetchDownloadedBytes,
    required this.cellularPrefetchSegmentDownloads,
    required this.cellularPlaybackDownloadedBytes,
    required this.segmentDownloads,
    required this.repeatedSegmentDownloads,
    required this.playlistDownloads,
    required this.playlistCacheHits,
    required this.segmentCacheHits,
    required this.uniqueDocsDownloaded,
    required this.peakConcurrentDownloads,
    required this.peakParallelDocDownloads,
    required this.peakOffscreenParallelDownloads,
    required this.variantSwitchesObserved,
    required List<HlsDocUsageSummary> topDocs,
    required List<String> anomalies,
  })  : topDocs = List<HlsDocUsageSummary>.from(topDocs, growable: false),
        anomalies = List<String>.from(anomalies, growable: false);

  final String label;
  final Duration elapsed;
  final String networkType;
  final int downloadedBytes;
  final int cacheServedBytes;
  final int visibleDownloadedBytes;
  final int offscreenDownloadedBytes;
  final int backgroundDownloadedBytes;
  final int visibleSegmentDownloads;
  final int backgroundSegmentDownloads;
  final int prefetchSegmentDownloads;
  final int prefetchDownloadedBytes;
  final int playbackDownloadedBytes;
  final int cellularDownloadedBytes;
  final int cellularBackgroundDownloadedBytes;
  final int cellularBackgroundSegmentDownloads;
  final int cellularPrefetchDownloadedBytes;
  final int cellularPrefetchSegmentDownloads;
  final int cellularPlaybackDownloadedBytes;
  final int segmentDownloads;
  final int repeatedSegmentDownloads;
  final int playlistDownloads;
  final int playlistCacheHits;
  final int segmentCacheHits;
  final int uniqueDocsDownloaded;
  final int peakConcurrentDownloads;
  final int peakParallelDocDownloads;
  final int peakOffscreenParallelDownloads;
  final int variantSwitchesObserved;
  final List<HlsDocUsageSummary> topDocs;
  final List<String> anomalies;

  double get mbPerMinute {
    final minutes = elapsed.inMilliseconds / 60000.0;
    if (minutes <= 0) return 0.0;
    return (downloadedBytes / (1024 * 1024)) / minutes;
  }

  double get avgMbPerVideo => uniqueDocsDownloaded == 0
      ? 0.0
      : (downloadedBytes / (1024 * 1024)) / uniqueDocsDownloaded;

  double get backgroundMbPerMinute {
    final minutes = elapsed.inMilliseconds / 60000.0;
    if (minutes <= 0) return 0.0;
    return (backgroundDownloadedBytes / (1024 * 1024)) / minutes;
  }

  double get cellularMbPerMinute {
    final minutes = elapsed.inMilliseconds / 60000.0;
    if (minutes <= 0) return 0.0;
    return (cellularDownloadedBytes / (1024 * 1024)) / minutes;
  }

  double get cellularBackgroundRatio {
    if (cellularDownloadedBytes <= 0) return 0.0;
    return cellularBackgroundDownloadedBytes / cellularDownloadedBytes;
  }

  double get cacheReuseRatio {
    final total = downloadedBytes + cacheServedBytes;
    if (total <= 0) return 0.0;
    return cacheServedBytes / total;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'label': label,
        'elapsedSeconds': elapsed.inMilliseconds / 1000.0,
        'networkType': networkType,
        'downloadedBytes': downloadedBytes,
        'downloadedMb': downloadedBytes / (1024 * 1024),
        'cacheServedBytes': cacheServedBytes,
        'cacheServedMb': cacheServedBytes / (1024 * 1024),
        'visibleDownloadedBytes': visibleDownloadedBytes,
        'offscreenDownloadedBytes': offscreenDownloadedBytes,
        'backgroundDownloadedBytes': backgroundDownloadedBytes,
        'backgroundDownloadedMb': backgroundDownloadedBytes / (1024 * 1024),
        'visibleSegmentDownloads': visibleSegmentDownloads,
        'backgroundSegmentDownloads': backgroundSegmentDownloads,
        'prefetchSegmentDownloads': prefetchSegmentDownloads,
        'prefetchDownloadedBytes': prefetchDownloadedBytes,
        'playbackDownloadedBytes': playbackDownloadedBytes,
        'cellularDownloadedBytes': cellularDownloadedBytes,
        'cellularDownloadedMb': cellularDownloadedBytes / (1024 * 1024),
        'cellularBackgroundDownloadedBytes': cellularBackgroundDownloadedBytes,
        'cellularBackgroundDownloadedMb':
            cellularBackgroundDownloadedBytes / (1024 * 1024),
        'cellularBackgroundSegmentDownloads':
            cellularBackgroundSegmentDownloads,
        'cellularPrefetchDownloadedBytes': cellularPrefetchDownloadedBytes,
        'cellularPrefetchSegmentDownloads': cellularPrefetchSegmentDownloads,
        'cellularPlaybackDownloadedBytes': cellularPlaybackDownloadedBytes,
        'segmentDownloads': segmentDownloads,
        'repeatedSegmentDownloads': repeatedSegmentDownloads,
        'playlistDownloads': playlistDownloads,
        'playlistCacheHits': playlistCacheHits,
        'segmentCacheHits': segmentCacheHits,
        'uniqueDocsDownloaded': uniqueDocsDownloaded,
        'peakConcurrentDownloads': peakConcurrentDownloads,
        'peakParallelDocDownloads': peakParallelDocDownloads,
        'peakOffscreenParallelDownloads': peakOffscreenParallelDownloads,
        'variantSwitchesObserved': variantSwitchesObserved,
        'mbPerMinute': mbPerMinute,
        'backgroundMbPerMinute': backgroundMbPerMinute,
        'cellularMbPerMinute': cellularMbPerMinute,
        'avgMbPerVideo': avgMbPerVideo,
        'cacheReuseRatio': cacheReuseRatio,
        'cellularBackgroundRatio': cellularBackgroundRatio,
        'topDocs': topDocs.map((e) => e.toJson()).toList(growable: false),
        'anomalies': List<String>.from(anomalies, growable: false),
      };
}

class _InFlightTransfer {
  const _InFlightTransfer({
    required this.docId,
    required this.segmentKey,
    required this.source,
    required this.startedAt,
    this.ownerInfo,
    this.tierInfo,
  });

  final String docId;
  final String segmentKey;
  final HlsTrafficSource source;
  final DateTime startedAt;
  final Map<String, dynamic>? ownerInfo;
  final Map<String, dynamic>? tierInfo;
}

class _VariantCatalog {
  _VariantCatalog({required this.docId});

  final String docId;
  final Map<String, _VariantInfo> variants = <String, _VariantInfo>{};
}

class _VariantInfo {
  _VariantInfo({
    required this.key,
    this.bandwidth = 0,
    this.resolution,
    List<M3U8Segment>? segments,
  }) : segments = List<M3U8Segment>.from(
          segments ?? const <M3U8Segment>[],
          growable: false,
        );

  final String key;
  final int bandwidth;
  final String? resolution;
  List<M3U8Segment> segments;

  double? segmentDurationFor(String segmentKey) {
    final fileName = segmentKey.split('/').last;
    for (final segment in segments) {
      if (segment.uri.split('/').last == fileName) {
        return segment.duration;
      }
    }
    return null;
  }
}

class _DocAccumulator {
  _DocAccumulator({required this.docId});

  final String docId;
  int downloadedBytes = 0;
  int cacheServedBytes = 0;
  int prefetchDownloadedBytes = 0;
  int playbackDownloadedBytes = 0;
  int segmentDownloads = 0;
  int repeatedSegmentDownloads = 0;
  int playlistDownloads = 0;
  int playlistCacheHits = 0;
  int segmentCacheHits = 0;
  final Set<String> variantKeys = <String>{};
  final List<double> segmentDurationsSec = <double>[];
  final List<int> segmentSizesBytes = <int>[];

  HlsDocUsageSummary toSummary() {
    final avgDuration = segmentDurationsSec.isEmpty
        ? 0.0
        : segmentDurationsSec.reduce((a, b) => a + b) /
            segmentDurationsSec.length;
    final maxDuration = segmentDurationsSec.isEmpty
        ? 0.0
        : segmentDurationsSec.reduce(math.max);
    final minDuration = segmentDurationsSec.isEmpty
        ? 0.0
        : segmentDurationsSec.reduce(math.min);
    final avgSizeKb = segmentSizesBytes.isEmpty
        ? 0.0
        : (segmentSizesBytes.reduce((a, b) => a + b) /
                segmentSizesBytes.length) /
            1024.0;
    final maxSizeKb = segmentSizesBytes.isEmpty
        ? 0.0
        : segmentSizesBytes.reduce(math.max) / 1024.0;

    return HlsDocUsageSummary(
      docId: docId,
      downloadedBytes: downloadedBytes,
      cacheServedBytes: cacheServedBytes,
      downloadedSegments: segmentDownloads,
      repeatedSegmentDownloads: repeatedSegmentDownloads,
      playlistDownloads: playlistDownloads,
      playlistCacheHits: playlistCacheHits,
      variantKeys: variantKeys.toList()..sort(),
      avgSegmentDurationSec: avgDuration,
      maxSegmentDurationSec: maxDuration,
      minSegmentDurationSec: minDuration,
      avgSegmentSizeKb: avgSizeKb,
      maxSegmentSizeKb: maxSizeKb,
    );
  }
}
