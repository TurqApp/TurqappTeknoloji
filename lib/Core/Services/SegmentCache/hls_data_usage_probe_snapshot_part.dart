part of 'hls_data_usage_probe.dart';

extension HlsDataUsageProbeSnapshotPart on HlsDataUsageProbe {
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
}
