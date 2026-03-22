import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'm3u8_parser.dart';

enum HlsTrafficSource {
  playback,
  prefetch,
}

enum HlsDebugNetworkProfile {
  fast,
  slow,
  unstable,
}

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
        'variantKeys': variantKeys,
        'avgSegmentDurationSec': avgSegmentDurationSec,
        'maxSegmentDurationSec': maxSegmentDurationSec,
        'minSegmentDurationSec': minSegmentDurationSec,
        'avgSegmentSizeKb': avgSegmentSizeKb,
        'maxSegmentSizeKb': maxSegmentSizeKb,
      };
}

class HlsDataUsageSnapshot {
  const HlsDataUsageSnapshot({
    required this.label,
    required this.elapsed,
    required this.downloadedBytes,
    required this.cacheServedBytes,
    required this.visibleDownloadedBytes,
    required this.offscreenDownloadedBytes,
    required this.prefetchDownloadedBytes,
    required this.playbackDownloadedBytes,
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
    required this.topDocs,
    required this.anomalies,
  });

  final String label;
  final Duration elapsed;
  final int downloadedBytes;
  final int cacheServedBytes;
  final int visibleDownloadedBytes;
  final int offscreenDownloadedBytes;
  final int prefetchDownloadedBytes;
  final int playbackDownloadedBytes;
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

  double get cacheReuseRatio {
    final total = downloadedBytes + cacheServedBytes;
    if (total <= 0) return 0.0;
    return cacheServedBytes / total;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'label': label,
        'elapsedSeconds': elapsed.inMilliseconds / 1000.0,
        'downloadedBytes': downloadedBytes,
        'downloadedMb': downloadedBytes / (1024 * 1024),
        'cacheServedBytes': cacheServedBytes,
        'cacheServedMb': cacheServedBytes / (1024 * 1024),
        'visibleDownloadedBytes': visibleDownloadedBytes,
        'offscreenDownloadedBytes': offscreenDownloadedBytes,
        'prefetchDownloadedBytes': prefetchDownloadedBytes,
        'playbackDownloadedBytes': playbackDownloadedBytes,
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
        'avgMbPerVideo': avgMbPerVideo,
        'cacheReuseRatio': cacheReuseRatio,
        'topDocs': topDocs.map((e) => e.toJson()).toList(),
        'anomalies': anomalies,
      };
}

class HlsDataUsageProbe extends GetxController {
  static HlsDataUsageProbe? maybeFind() {
    final isRegistered = Get.isRegistered<HlsDataUsageProbe>();
    if (!isRegistered) return null;
    return Get.find<HlsDataUsageProbe>();
  }

  static HlsDataUsageProbe ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(HlsDataUsageProbe(), permanent: true);
  }

  final List<HlsTransferEvent> _events = <HlsTransferEvent>[];
  final Map<String, int> _segmentDownloads = <String, int>{};
  final Map<String, int> _segmentCacheHits = <String, int>{};
  final Map<String, _VariantCatalog> _variantCatalogs =
      <String, _VariantCatalog>{};
  final Map<String, _DocAccumulator> _docUsage = <String, _DocAccumulator>{};
  final Map<String, _InFlightTransfer> _inFlight =
      <String, _InFlightTransfer>{};
  final math.Random _random = math.Random(7);

  DateTime _startedAt = DateTime.now();
  String _label = 'default';
  String? _visibleDocId;
  HlsDebugNetworkProfile _networkProfile = HlsDebugNetworkProfile.fast;
  int _peakConcurrentDownloads = 0;
  int _peakParallelDocDownloads = 0;
  int _peakOffscreenParallelDownloads = 0;
  int _variantSwitchesObserved = 0;
  String? _lastVisibleVariantKey;

  String get sessionLabel => _label;
  HlsDebugNetworkProfile get networkProfile => _networkProfile;

  void resetSession({String label = 'default'}) {
    _events.clear();
    _segmentDownloads.clear();
    _segmentCacheHits.clear();
    _variantCatalogs.clear();
    _docUsage.clear();
    _inFlight.clear();
    _startedAt = DateTime.now();
    _label = label;
    _visibleDocId = null;
    _networkProfile = HlsDebugNetworkProfile.fast;
    _peakConcurrentDownloads = 0;
    _peakParallelDocDownloads = 0;
    _peakOffscreenParallelDownloads = 0;
    _variantSwitchesObserved = 0;
    _lastVisibleVariantKey = null;
  }

  void setVisibleDoc(String? docId) {
    _visibleDocId = docId;
  }

  void debugSetNetworkProfile(HlsDebugNetworkProfile profile) {
    _networkProfile = profile;
  }

  Future<void> maybeApplyDebugDelay({
    required bool isPlaylist,
    required HlsTrafficSource source,
  }) async {
    if (!kDebugMode) return;
    if (source != HlsTrafficSource.playback) return;

    Duration delay;
    switch (_networkProfile) {
      case HlsDebugNetworkProfile.fast:
        delay = isPlaylist
            ? const Duration(milliseconds: 25)
            : const Duration(milliseconds: 35);
        break;
      case HlsDebugNetworkProfile.slow:
        delay = isPlaylist
            ? const Duration(milliseconds: 420)
            : const Duration(milliseconds: 1100);
        break;
      case HlsDebugNetworkProfile.unstable:
        final base = isPlaylist ? 180 : 420;
        final jitter = _random.nextInt(isPlaylist ? 380 : 1200);
        delay = Duration(milliseconds: base + jitter);
        break;
    }

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }

  void recordMasterPlaylist({
    required String docId,
    required String path,
    required String content,
    required HlsTrafficSource source,
    required bool cacheHit,
  }) {
    final catalog = _variantCatalogs.putIfAbsent(
        docId, () => _VariantCatalog(docId: docId));
    for (final variant in M3U8Parser.parseVariants(content)) {
      final key = _variantKeyFromPlaylistPath(variant.uri);
      if (key == null) continue;
      catalog.variants[key] = _VariantInfo(
        key: key,
        bandwidth: variant.bandwidth,
        resolution: variant.resolution,
      );
    }
    _recordPlaylistEvent(
      docId: docId,
      pathKey: path,
      bytes: content.length,
      cacheHit: cacheHit,
      source: source,
    );
  }

  void recordVariantPlaylist({
    required String docId,
    required String path,
    required String content,
    required HlsTrafficSource source,
    required bool cacheHit,
  }) {
    final variantKey = _variantKeyFromPlaylistPath(path);
    if (variantKey != null) {
      final catalog = _variantCatalogs.putIfAbsent(
          docId, () => _VariantCatalog(docId: docId));
      final existing = catalog.variants[variantKey];
      final segments = M3U8Parser.parseSegments(content);
      catalog.variants[variantKey] = (existing ?? _VariantInfo(key: variantKey))
        ..segments = segments;
    }

    _recordPlaylistEvent(
      docId: docId,
      pathKey: path,
      bytes: content.length,
      cacheHit: cacheHit,
      source: source,
    );
  }

  void recordSegmentStart({
    required String docId,
    required String segmentKey,
    required HlsTrafficSource source,
  }) {
    final transferKey = '$docId|$segmentKey|${source.name}';
    _inFlight[transferKey] = _InFlightTransfer(
      docId: docId,
      segmentKey: segmentKey,
      source: source,
      startedAt: DateTime.now(),
    );
    _recomputeConcurrency();
  }

  void recordSegmentTransfer({
    required String docId,
    required String segmentKey,
    required int bytes,
    required HlsTrafficSource source,
    required bool cacheHit,
  }) {
    final transferKey = '$docId|$segmentKey|${source.name}';
    _inFlight.remove(transferKey);
    _recomputeConcurrency();

    final variantKey = _variantKeyFromSegmentKey(segmentKey);
    final event = HlsTransferEvent(
      at: DateTime.now(),
      docId: docId,
      pathKey: segmentKey,
      source: source,
      bytes: bytes,
      cacheHit: cacheHit,
      visibleDocId: _visibleDocId,
      variantKey: variantKey,
      kind: 'segment',
    );
    _events.add(event);

    final doc =
        _docUsage.putIfAbsent(docId, () => _DocAccumulator(docId: docId));
    if (cacheHit) {
      doc.cacheServedBytes += bytes;
      doc.segmentCacheHits += 1;
      _segmentCacheHits.update('$docId|$segmentKey', (value) => value + 1,
          ifAbsent: () => 1);
    } else {
      doc.downloadedBytes += bytes;
      doc.segmentDownloads += 1;
      if (source == HlsTrafficSource.prefetch) {
        doc.prefetchDownloadedBytes += bytes;
      } else {
        doc.playbackDownloadedBytes += bytes;
      }
      final count = _segmentDownloads.update(
          '$docId|$segmentKey', (value) => value + 1,
          ifAbsent: () => 1);
      if (count > 1) {
        doc.repeatedSegmentDownloads += 1;
      }
    }

    if (variantKey != null) {
      doc.variantKeys.add(variantKey);
      final variant = _variantCatalogs[docId]?.variants[variantKey];
      final duration = variant?.segmentDurationFor(segmentKey);
      if (duration != null && duration > 0) {
        doc.segmentDurationsSec.add(duration);
      }
      if (bytes > 0) {
        doc.segmentSizesBytes.add(bytes);
      }
      if (!cacheHit && event.isVisibleAtTransfer) {
        if (_lastVisibleVariantKey != null &&
            _lastVisibleVariantKey != variantKey) {
          _variantSwitchesObserved += 1;
        }
        _lastVisibleVariantKey = variantKey;
      }
    }
  }

  HlsDataUsageSnapshot snapshot() {
    final elapsed = DateTime.now().difference(_startedAt);
    var downloadedBytes = 0;
    var cacheServedBytes = 0;
    var visibleDownloadedBytes = 0;
    var offscreenDownloadedBytes = 0;
    var prefetchDownloadedBytes = 0;
    var playbackDownloadedBytes = 0;
    var segmentDownloads = 0;
    var repeatedSegmentDownloads = 0;
    var playlistDownloads = 0;
    var playlistCacheHits = 0;
    var segmentCacheHits = 0;

    for (final doc in _docUsage.values) {
      downloadedBytes += doc.downloadedBytes;
      cacheServedBytes += doc.cacheServedBytes;
      prefetchDownloadedBytes += doc.prefetchDownloadedBytes;
      playbackDownloadedBytes += doc.playbackDownloadedBytes;
      segmentDownloads += doc.segmentDownloads;
      repeatedSegmentDownloads += doc.repeatedSegmentDownloads;
      playlistDownloads += doc.playlistDownloads;
      playlistCacheHits += doc.playlistCacheHits;
      segmentCacheHits += doc.segmentCacheHits;
    }

    for (final event in _events) {
      if (event.kind != 'segment' || event.cacheHit) continue;
      if (event.isVisibleAtTransfer) {
        visibleDownloadedBytes += event.bytes;
      } else {
        offscreenDownloadedBytes += event.bytes;
      }
    }

    final topDocs = _docUsage.values.map((doc) => doc.toSummary()).toList()
      ..sort((a, b) => b.downloadedBytes.compareTo(a.downloadedBytes));

    final anomalies = <String>[];
    final mbPerMinute = elapsed.inMilliseconds == 0
        ? 0.0
        : (downloadedBytes / (1024 * 1024)) /
            (elapsed.inMilliseconds / 60000.0);
    if (mbPerMinute > 18.0) {
      anomalies.add(
          'HLS data usage too high per minute: ${mbPerMinute.toStringAsFixed(2)} MB/min');
    }
    if (repeatedSegmentDownloads > 3) {
      anomalies.add(
          'Repeated segment downloads observed: $repeatedSegmentDownloads');
    }
    if (_peakParallelDocDownloads > 4) {
      anomalies.add(
          'Too many parallel HLS doc downloads: $_peakParallelDocDownloads');
    }
    if (_peakOffscreenParallelDownloads > 2) {
      anomalies.add(
          'Off-screen parallel HLS downloads too high: $_peakOffscreenParallelDownloads');
    }
    for (final doc in topDocs.take(5)) {
      if (doc.maxSegmentDurationSec > 3.2 || doc.minSegmentDurationSec < 0.8) {
        anomalies.add(
          'Unexpected segment duration window for ${doc.docId}: '
          '${doc.minSegmentDurationSec.toStringAsFixed(2)}-${doc.maxSegmentDurationSec.toStringAsFixed(2)}s',
        );
      }
      if (doc.maxSegmentSizeKb > 2048) {
        anomalies.add(
            'Oversized HLS segment for ${doc.docId}: ${doc.maxSegmentSizeKb.toStringAsFixed(1)} KB');
      }
    }

    return HlsDataUsageSnapshot(
      label: _label,
      elapsed: elapsed,
      downloadedBytes: downloadedBytes,
      cacheServedBytes: cacheServedBytes,
      visibleDownloadedBytes: visibleDownloadedBytes,
      offscreenDownloadedBytes: offscreenDownloadedBytes,
      prefetchDownloadedBytes: prefetchDownloadedBytes,
      playbackDownloadedBytes: playbackDownloadedBytes,
      segmentDownloads: segmentDownloads,
      repeatedSegmentDownloads: repeatedSegmentDownloads,
      playlistDownloads: playlistDownloads,
      playlistCacheHits: playlistCacheHits,
      segmentCacheHits: segmentCacheHits,
      uniqueDocsDownloaded: _docUsage.length,
      peakConcurrentDownloads: _peakConcurrentDownloads,
      peakParallelDocDownloads: _peakParallelDocDownloads,
      peakOffscreenParallelDownloads: _peakOffscreenParallelDownloads,
      variantSwitchesObserved: _variantSwitchesObserved,
      topDocs: topDocs.take(10).toList(),
      anomalies: anomalies,
    );
  }

  Map<String, dynamic> snapshotJson() => snapshot().toJson();

  void _recordPlaylistEvent({
    required String docId,
    required String pathKey,
    required int bytes,
    required bool cacheHit,
    required HlsTrafficSource source,
  }) {
    final doc =
        _docUsage.putIfAbsent(docId, () => _DocAccumulator(docId: docId));
    if (cacheHit) {
      doc.playlistCacheHits += 1;
    } else {
      doc.playlistDownloads += 1;
    }
    _events.add(HlsTransferEvent(
      at: DateTime.now(),
      docId: docId,
      pathKey: pathKey,
      source: source,
      bytes: bytes,
      cacheHit: cacheHit,
      visibleDocId: _visibleDocId,
      variantKey: _variantKeyFromPlaylistPath(pathKey),
      kind: 'playlist',
    ));
  }

  String? _variantKeyFromPlaylistPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final match =
        RegExp(r'/hls/([^/]+)/playlist\.m3u8$').firstMatch(normalized);
    if (match != null) return match.group(1);

    final relativeMatch =
        RegExp(r'^([^/]+)/playlist\.m3u8$').firstMatch(normalized);
    return relativeMatch?.group(1);
  }

  String? _variantKeyFromSegmentKey(String segmentKey) {
    final normalized = segmentKey.replaceAll('\\', '/');
    final slash = normalized.indexOf('/');
    if (slash <= 0) return null;
    return normalized.substring(0, slash);
  }

  void _recomputeConcurrency() {
    _peakConcurrentDownloads =
        math.max(_peakConcurrentDownloads, _inFlight.length);
    final activeDocs = _inFlight.values.map((e) => e.docId).toSet();
    _peakParallelDocDownloads =
        math.max(_peakParallelDocDownloads, activeDocs.length);
    final offscreen = _inFlight.values
        .where((e) => _visibleDocId == null || e.docId != _visibleDocId)
        .length;
    _peakOffscreenParallelDownloads =
        math.max(_peakOffscreenParallelDownloads, offscreen);
  }
}

class _InFlightTransfer {
  const _InFlightTransfer({
    required this.docId,
    required this.segmentKey,
    required this.source,
    required this.startedAt,
  });

  final String docId;
  final String segmentKey;
  final HlsTrafficSource source;
  final DateTime startedAt;
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
  }) : segments = segments ?? <M3U8Segment>[];

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
