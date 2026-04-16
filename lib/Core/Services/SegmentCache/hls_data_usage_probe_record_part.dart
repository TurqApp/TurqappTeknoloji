part of 'hls_data_usage_probe.dart';

extension HlsDataUsageProbeRecordPart on HlsDataUsageProbe {
  static const Duration _offscreenLeakAlertCooldown = Duration(seconds: 3);

  String _currentNetworkTypeName() {
    final network = NetworkAwarenessService.maybeFind();
    return (network?.currentNetwork ?? NetworkType.none).name;
  }

  void _recordOffscreenLeakSignal(HlsTransferEvent event) {
    if (event.kind != 'segment' || event.cacheHit || event.isVisibleAtTransfer) {
      return;
    }
    final visibleDocId = (event.visibleDocId ?? '').trim();
    final docId = event.docId.trim();
    if (docId.isEmpty || visibleDocId.isEmpty || visibleDocId == docId) {
      return;
    }
    final alertKey = '$docId|$visibleDocId|${event.source.name}';
    final now = DateTime.now();
    final previous = _offscreenLeakAlerts[alertKey];
    if (previous != null &&
        now.difference(previous) < _offscreenLeakAlertCooldown) {
      return;
    }
    _offscreenLeakAlerts[alertKey] = now;
    final feedTier = maybeFindPrefetchScheduler()?.classifyFeedTransferDoc(docId);
    final allowedSegmentWarm = feedTier?['allowedSegmentWarm'] == true;
    final payload = <String, dynamic>{
      'docId': docId,
      'visibleDocId': visibleDocId,
      'source': event.source.name,
      'bytes': event.bytes,
      'networkType': event.networkType,
      'segmentKey': event.pathKey,
      'feedTier': feedTier?['tier'] ?? 'unknown',
      'feedDistance': feedTier?['distance'],
      'allowedSegmentWarm': allowedSegmentWarm,
      'allowedCacheOnly': feedTier?['allowedCacheOnly'],
      'label': _label,
    };
    debugPrint(
      '[HlsOffscreenLeak] signal=${allowedSegmentWarm ? 'offscreen_segment_allowed_window' : 'offscreen_segment_leak_after_stop'} payload=$payload',
    );
    if (allowedSegmentWarm) {
      return;
    }
    ensureRuntimeInvariantGuard().record(
      surface: 'feed',
      invariantKey: 'offscreen_segment_leak_after_stop',
      message: 'Off-screen segment transfer continued for a non-visible doc',
      payload: payload,
    );
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
        ..segments = List<M3U8Segment>.from(segments, growable: false);
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
      networkType: _currentNetworkTypeName(),
    );
    _events.add(event);
    _recordOffscreenLeakSignal(event);

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

    if (!cacheHit) {
      _publishMobileBytesKpiIfNeeded();
    }
  }

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
      networkType: _currentNetworkTypeName(),
    ));

    if (!cacheHit) {
      _publishMobileBytesKpiIfNeeded();
    }
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
