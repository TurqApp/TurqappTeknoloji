part of 'hls_data_usage_probe.dart';

extension HlsDataUsageProbeSnapshotPart on HlsDataUsageProbe {
  HlsDataUsageSnapshot snapshot() {
    final elapsed = DateTime.now().difference(_startedAt);
    final network = NetworkAwarenessService.maybeFind();
    final networkType = (network?.currentNetwork ?? NetworkType.none).name;
    var downloadedBytes = 0;
    var cacheServedBytes = 0;
    var visibleDownloadedBytes = 0;
    var offscreenDownloadedBytes = 0;
    var backgroundDownloadedBytes = 0;
    var visibleSegmentDownloads = 0;
    var backgroundSegmentDownloads = 0;
    var prefetchSegmentDownloads = 0;
    var prefetchDownloadedBytes = 0;
    var playbackDownloadedBytes = 0;
    var cellularDownloadedBytes = 0;
    var cellularBackgroundDownloadedBytes = 0;
    var cellularBackgroundSegmentDownloads = 0;
    var cellularPrefetchDownloadedBytes = 0;
    var cellularPrefetchSegmentDownloads = 0;
    var cellularPlaybackDownloadedBytes = 0;
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
      final isCellular = event.networkType == NetworkType.cellular.name;
      if (event.isVisibleAtTransfer) {
        visibleDownloadedBytes += event.bytes;
        visibleSegmentDownloads += 1;
      } else {
        offscreenDownloadedBytes += event.bytes;
        backgroundDownloadedBytes += event.bytes;
        backgroundSegmentDownloads += 1;
        if (isCellular) {
          cellularBackgroundDownloadedBytes += event.bytes;
          cellularBackgroundSegmentDownloads += 1;
        }
      }
      if (event.source == HlsTrafficSource.prefetch) {
        prefetchSegmentDownloads += 1;
      }
      if (isCellular) {
        cellularDownloadedBytes += event.bytes;
        if (event.source == HlsTrafficSource.prefetch) {
          cellularPrefetchDownloadedBytes += event.bytes;
          cellularPrefetchSegmentDownloads += 1;
        } else {
          cellularPlaybackDownloadedBytes += event.bytes;
        }
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
    final expectedMinSegmentDuration = math.max(
      0.2,
      math.min(
            HlsSegmentPolicy.firstSegmentSeconds.toDouble(),
            HlsSegmentPolicy.nextSegmentSeconds.toDouble(),
          ) -
          0.8,
    );
    final expectedMaxSegmentDuration = math.max(
          HlsSegmentPolicy.firstSegmentSeconds.toDouble(),
          HlsSegmentPolicy.nextSegmentSeconds.toDouble(),
        ) +
        0.8;
    for (final doc in topDocs.take(5)) {
      if (doc.maxSegmentDurationSec > expectedMaxSegmentDuration ||
          doc.minSegmentDurationSec < expectedMinSegmentDuration) {
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
      networkType: networkType,
      downloadedBytes: downloadedBytes,
      cacheServedBytes: cacheServedBytes,
      visibleDownloadedBytes: visibleDownloadedBytes,
      offscreenDownloadedBytes: offscreenDownloadedBytes,
      backgroundDownloadedBytes: backgroundDownloadedBytes,
      visibleSegmentDownloads: visibleSegmentDownloads,
      backgroundSegmentDownloads: backgroundSegmentDownloads,
      prefetchSegmentDownloads: prefetchSegmentDownloads,
      prefetchDownloadedBytes: prefetchDownloadedBytes,
      playbackDownloadedBytes: playbackDownloadedBytes,
      cellularDownloadedBytes: cellularDownloadedBytes,
      cellularBackgroundDownloadedBytes: cellularBackgroundDownloadedBytes,
      cellularBackgroundSegmentDownloads: cellularBackgroundSegmentDownloads,
      cellularPrefetchDownloadedBytes: cellularPrefetchDownloadedBytes,
      cellularPrefetchSegmentDownloads: cellularPrefetchSegmentDownloads,
      cellularPlaybackDownloadedBytes: cellularPlaybackDownloadedBytes,
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

  void _publishMobileBytesKpiIfNeeded({bool force = false}) {
    final playbackKpi = maybeFindPlaybackKpiService();
    if (playbackKpi == null) return;

    final usage = snapshot();
    if (!force && usage.downloadedBytes <= 0) return;
    final now = DateTime.now();
    const recentWindow = Duration(seconds: 15);
    var recentDownloadedBytes = 0;
    var recentBackgroundDownloadedBytes = 0;
    var recentPrefetchDownloadedBytes = 0;
    var recentPlaybackDownloadedBytes = 0;
    var recentSegmentDownloads = 0;
    var recentBackgroundSegmentDownloads = 0;
    var recentPrefetchSegmentDownloads = 0;
    var recentCellularDownloadedBytes = 0;
    var recentCellularBackgroundDownloadedBytes = 0;
    for (final event in _events) {
      if (event.cacheHit) continue;
      if (now.difference(event.at) > recentWindow) continue;
      recentDownloadedBytes += event.bytes;
      final isCellular = event.networkType == NetworkType.cellular.name;
      if (isCellular) {
        recentCellularDownloadedBytes += event.bytes;
      }
      if (event.kind != 'segment') continue;
      recentSegmentDownloads += 1;
      if (event.isVisibleAtTransfer) {
        if (event.source == HlsTrafficSource.prefetch) {
          recentPrefetchDownloadedBytes += event.bytes;
          recentPrefetchSegmentDownloads += 1;
        } else {
          recentPlaybackDownloadedBytes += event.bytes;
        }
        continue;
      }
      recentBackgroundDownloadedBytes += event.bytes;
      recentBackgroundSegmentDownloads += 1;
      if (isCellular) {
        recentCellularBackgroundDownloadedBytes += event.bytes;
      }
      if (event.source == HlsTrafficSource.prefetch) {
        recentPrefetchDownloadedBytes += event.bytes;
        recentPrefetchSegmentDownloads += 1;
      } else {
        recentPlaybackDownloadedBytes += event.bytes;
      }
    }

    const int totalBucketBytes = 256 * 1024;
    const int detailBucketBytes = 128 * 1024;
    final signature = [
      usage.networkType,
      't${usage.downloadedBytes ~/ totalBucketBytes}',
      'bg${usage.backgroundDownloadedBytes ~/ detailBucketBytes}',
      'rbg${recentBackgroundDownloadedBytes ~/ detailBucketBytes}',
      'pf${usage.prefetchDownloadedBytes ~/ detailBucketBytes}',
      'cell${usage.cellularDownloadedBytes ~/ detailBucketBytes}',
      'cbg${usage.cellularBackgroundDownloadedBytes ~/ detailBucketBytes}',
      'pk${usage.peakOffscreenParallelDownloads}',
    ].join('|');

    if (!force && signature == _mobileBytesKpiSignature) {
      return;
    }
    _mobileBytesKpiSignature = signature;

    playbackKpi.track(
      PlaybackKpiEventType.mobileBytesPerMinute,
      {
        'label': usage.label,
        'networkType': usage.networkType,
        'downloadedBytes': usage.downloadedBytes,
        'backgroundDownloadedBytes': usage.backgroundDownloadedBytes,
        'backgroundSegmentDownloads': usage.backgroundSegmentDownloads,
        'prefetchDownloadedBytes': usage.prefetchDownloadedBytes,
        'prefetchSegmentDownloads': usage.prefetchSegmentDownloads,
        'playbackDownloadedBytes': usage.playbackDownloadedBytes,
        'recentWindowSeconds': recentWindow.inSeconds,
        'recentDownloadedBytes': recentDownloadedBytes,
        'recentBackgroundDownloadedBytes': recentBackgroundDownloadedBytes,
        'recentBackgroundSegmentDownloads': recentBackgroundSegmentDownloads,
        'recentPrefetchDownloadedBytes': recentPrefetchDownloadedBytes,
        'recentPrefetchSegmentDownloads': recentPrefetchSegmentDownloads,
        'recentPlaybackDownloadedBytes': recentPlaybackDownloadedBytes,
        'recentSegmentDownloads': recentSegmentDownloads,
        'recentCellularDownloadedBytes': recentCellularDownloadedBytes,
        'recentCellularBackgroundDownloadedBytes':
            recentCellularBackgroundDownloadedBytes,
        'cellularDownloadedBytes': usage.cellularDownloadedBytes,
        'cellularBackgroundDownloadedBytes':
            usage.cellularBackgroundDownloadedBytes,
        'cellularBackgroundSegmentDownloads':
            usage.cellularBackgroundSegmentDownloads,
        'cellularPrefetchDownloadedBytes':
            usage.cellularPrefetchDownloadedBytes,
        'cellularPrefetchSegmentDownloads':
            usage.cellularPrefetchSegmentDownloads,
        'cellularPlaybackDownloadedBytes':
            usage.cellularPlaybackDownloadedBytes,
        'mbPerMinute': usage.mbPerMinute,
        'backgroundMbPerMinute': usage.backgroundMbPerMinute,
        'cellularMbPerMinute': usage.cellularMbPerMinute,
        'cellularBackgroundRatio': usage.cellularBackgroundRatio,
        'peakOffscreenParallelDownloads': usage.peakOffscreenParallelDownloads,
        'visibleDocId': _visibleDocId,
      },
    );
  }
}
