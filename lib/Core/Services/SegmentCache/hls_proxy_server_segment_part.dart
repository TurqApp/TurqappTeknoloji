part of 'hls_proxy_server.dart';

extension HlsProxyServerSegmentPart on HLSProxyServer {
  void _logPlaybackSegmentServe({
    required String docId,
    required String segmentKey,
    required bool cacheHit,
    required int bytes,
    required String path,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[HlsSegmentServe] doc=$docId segment=$segmentKey cacheHit=$cacheHit bytes=$bytes path=$path',
    );
  }

  Future<void> _respondStalePlaybackSegment(HttpRequest request) async {
    request.response
      ..statusCode = HttpStatus.gone
      ..write('Stale playback segment request')
      ..close();
  }

  Future<void> _warmAdjacentPlaybackSegment({
    required String docId,
    required String? playbackDocId,
    required String currentPath,
    required String currentSegmentKey,
    required SegmentCacheManager cacheManager,
  }) async {
    final policyDocId = playbackDocId ?? docId;
    if (!_canFetchSegmentOnDemandForDoc(
      docId,
      playbackDocID: playbackDocId,
    )) {
      return;
    }

    final currentRelativePath =
        currentPath.startsWith('/') ? currentPath.substring(1) : currentPath;
    final lastSlashIndex = currentRelativePath.lastIndexOf('/');
    if (lastSlashIndex < 0) return;

    final playlistRelativePath =
        '${currentRelativePath.substring(0, lastSlashIndex + 1)}playlist.m3u8';
    final playlistFile = cacheManager.getPlaylistFile(playlistRelativePath);
    if (playlistFile == null) return;

    String playlistContent;
    try {
      playlistContent = await playlistFile.readAsString();
    } catch (_) {
      return;
    }

    final segmentUris = M3U8Parser.segmentUris(playlistContent);
    if (segmentUris.length < 2) return;

    final currentSegmentName = currentSegmentKey.split('/').last;
    final currentIndex = segmentUris.indexWhere(
      (uri) => uri.split('/').last == currentSegmentName,
    );
    if (currentIndex < 0 || currentIndex + 1 >= segmentUris.length) return;

    final nextUri = segmentUris[currentIndex + 1];
    final segmentDir = currentSegmentKey.substring(
      0,
      currentSegmentKey.lastIndexOf('/') + 1,
    );
    final nextSegmentKey = '$segmentDir$nextUri';
    if (cacheManager.getSegmentFile(docId, nextSegmentKey) != null) return;
    if (playbackDocId != null &&
        playbackDocId != docId &&
        cacheManager.getSegmentFile(playbackDocId, nextSegmentKey) != null) {
      return;
    }

    final nextSegmentOrdinal =
        ShortSwipeSegmentGuard.segmentOrdinalFromKey(nextSegmentKey);
    if (nextSegmentOrdinal != null &&
        nextSegmentOrdinal > HlsSegmentPolicy.playbackWarmMaxSegmentOrdinal) {
      if (kDebugMode) {
        debugPrint(
          '[HlsPlaybackWarm] status=skip reason=max_segment_2 '
          'doc=$docId segment=$nextSegmentKey segmentOrdinal=$nextSegmentOrdinal',
        );
      }
      return;
    }

    final nextPath =
        '${currentPath.substring(0, currentPath.lastIndexOf('/') + 1)}$nextUri';
    if (_segmentFetchInFlight.containsKey(nextPath)) return;
    if (ShortSwipeSegmentGuard.shouldBlockPrefetchDispatchAfterSwipe(
      docId: policyDocId,
      segmentKey: nextSegmentKey,
      segmentOrdinal: nextSegmentOrdinal,
      cacheOrigin: 'playback_warm',
      queueLength: 0,
      activeDownloads: 0,
    )) {
      return;
    }

    unawaited(() async {
      try {
        final future =
            _fetchSegmentFromCDN('$_hlsProxyServerCdnOrigin$nextPath');
        _segmentFetchInFlight[nextPath] = future;
        final bytes = await future;
        if (!_canFetchSegmentOnDemandForDoc(
          docId,
          playbackDocID: playbackDocId,
        )) {
          return;
        }
        if (ShortSwipeSegmentGuard.shouldDropPrefetchWriteAfterSwipe(
          docId: policyDocId,
          segmentKey: nextSegmentKey,
          segmentOrdinal: nextSegmentOrdinal,
          cacheOrigin: 'playback_warm',
          queueLength: 0,
          activeDownloads: 0,
          bytes: bytes.length,
        )) {
          return;
        }
        await cacheManager.writeSegment(
          docId,
          nextSegmentKey,
          bytes,
          cacheOrigin: 'playback_warm',
        );
        _logPlaybackSegmentServe(
          docId: docId,
          segmentKey: nextSegmentKey,
          cacheHit: false,
          bytes: bytes.length,
          path: nextPath,
        );
      } catch (_) {
      } finally {
        _segmentFetchInFlight.remove(nextPath);
      }
    }());
  }

  String? _resolvePlaybackDocIdForRequest(
    String? mediaDocID,
    SegmentCacheManager? cacheManager,
  ) {
    final normalizedMediaDocID = HlsSegmentPolicy.normalizeDocId(mediaDocID);
    if (normalizedMediaDocID == null || normalizedMediaDocID.isEmpty) {
      return null;
    }
    final manager = maybeFindVideoStateManager();
    if (manager?.allowsOnDemandSegmentFetchFor(normalizedMediaDocID) == true) {
      return normalizedMediaDocID;
    }
    return cacheManager?.playbackDocIdForMediaDocId(normalizedMediaDocID) ??
        normalizedMediaDocID;
  }

  bool _canFetchSegmentOnDemandForDoc(
    String? docID, {
    String? playbackDocID,
  }) {
    if (!CacheNetworkPolicy.canFetchOnDemand) {
      return false;
    }
    final requestedDocId = HlsSegmentPolicy.normalizeDocId(playbackDocID) ??
        HlsSegmentPolicy.normalizeDocId(docID);
    if (requestedDocId == null || requestedDocId.isEmpty) {
      return true;
    }
    return VideoStateManager.instance.allowsOnDemandSegmentFetchFor(
      requestedDocId,
    );
  }

  /// Segment isteği (.ts) — cache'den veya CDN'den.
  Future<void> _handleSegment(
      HttpRequest request, String path, String? docID) async {
    final cacheManager = _getCacheManager();
    final metrics = cacheManager?.metrics;
    final probe = ensureHlsDataUsageProbe();
    final playbackDocID = _resolvePlaybackDocIdForRequest(docID, cacheManager);

    if (docID != null && cacheManager != null) {
      final segmentKey = _extractSegmentKey(path, docID);

      if (segmentKey != null) {
        var cacheDocID = docID;
        var cached = cacheManager.getSegmentFile(cacheDocID, segmentKey);
        if (cached == null && playbackDocID != null && playbackDocID != docID) {
          final playbackCached =
              cacheManager.getSegmentFile(playbackDocID, segmentKey);
          if (playbackCached != null) {
            cacheDocID = playbackDocID;
            cached = playbackCached;
          }
        }
        if (cached != null) {
          try {
            final bytes = await cached.readAsBytes();
            if (!_canFetchSegmentOnDemandForDoc(
              docID,
              playbackDocID: playbackDocID,
            )) {
              await _respondStalePlaybackSegment(request);
              return;
            }
            metrics?.recordHit(bytes.length);
            cacheManager.touchEntry(cacheDocID);
            final entry = cacheManager.getEntry(cacheDocID);
            probe.recordSegmentTransfer(
              docId: playbackDocID ?? docID,
              segmentKey: segmentKey,
              bytes: bytes.length,
              source: HlsTrafficSource.playback,
              cacheHit: true,
              cacheOriginOverride: entry?.segments[segmentKey]?.cacheOrigin,
            );
            _logPlaybackSegmentServe(
              docId: playbackDocID ?? docID,
              segmentKey: segmentKey,
              cacheHit: true,
              bytes: bytes.length,
              path: path,
            );

            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType('video', 'mp2t')
              ..headers.set('Access-Control-Allow-Origin', '*')
              ..headers
                  .set('Cache-Control', 'public, max-age=31536000, immutable')
              ..headers.set('Connection', 'keep-alive')
              ..headers.contentLength = bytes.length
              ..add(bytes)
              ..close();
            unawaited(
              _warmAdjacentPlaybackSegment(
                docId: docID,
                playbackDocId: playbackDocID,
                currentPath: path,
                currentSegmentKey: segmentKey,
                cacheManager: cacheManager,
              ),
            );
            return;
          } catch (_) {}
        }
      }
    }

    if (!_canFetchSegmentOnDemandForDoc(
      docID,
      playbackDocID: playbackDocID,
    )) {
      request.response
        ..statusCode = HttpStatus.serviceUnavailable
        ..write(CacheNetworkPolicy.segmentFetchBlockedReason)
        ..close();
      return;
    }

    final cdnUrl = '$_hlsProxyServerCdnOrigin$path';
    var ownsSegmentFetch = false;
    var servedFromInflight = false;
    try {
      final existing = _segmentFetchInFlight[path];
      final Uint8List bytes;
      if (existing != null) {
        servedFromInflight = true;
        bytes = await existing;
      } else {
        ownsSegmentFetch = true;
        if (docID != null) {
          final segmentKey = _extractSegmentKey(path, docID);
          if (segmentKey != null) {
            final segmentOrdinal =
                ShortSwipeSegmentGuard.segmentOrdinalFromKey(segmentKey);
            if (ShortSwipeSegmentGuard.shouldBlockPrefetchDispatchAfterSwipe(
              docId: playbackDocID ?? docID,
              segmentKey: segmentKey,
              segmentOrdinal: segmentOrdinal,
              cacheOrigin: 'playback',
              queueLength: 0,
              activeDownloads: 0,
            )) {
              await _respondStalePlaybackSegment(request);
              return;
            }
            probe.recordSegmentStart(
              docId: playbackDocID ?? docID,
              segmentKey: segmentKey,
              source: HlsTrafficSource.playback,
            );
          }
        }
        final future = _fetchSegmentFromCDN(cdnUrl);
        _segmentFetchInFlight[path] = future;
        bytes = await future;
      }

      await probe.maybeApplyDebugDelay(
        isPlaylist: false,
        source: HlsTrafficSource.playback,
      );
      if (!_canFetchSegmentOnDemandForDoc(
        docID,
        playbackDocID: playbackDocID,
      )) {
        if (docID != null) {
          final segmentKey = _extractSegmentKey(path, docID);
          if (segmentKey != null) {
            probe.cancelSegmentTransfer(
              docId: playbackDocID ?? docID,
              segmentKey: segmentKey,
              source: HlsTrafficSource.playback,
            );
          }
        }
        await _respondStalePlaybackSegment(request);
        return;
      }
      if (servedFromInflight) {
        metrics?.recordHit(bytes.length);
      } else {
        metrics?.recordMiss(bytes.length);
        _trackDownloadBytes(bytes.length);
      }

      if (docID != null && cacheManager != null) {
        final segmentKey = _extractSegmentKey(path, docID);
        if (segmentKey != null) {
          probe.recordSegmentTransfer(
            docId: playbackDocID ?? docID,
            segmentKey: segmentKey,
            bytes: bytes.length,
            source: HlsTrafficSource.playback,
            cacheHit: servedFromInflight,
            cacheOriginOverride: servedFromInflight ? 'inflight_reuse' : null,
          );
          _logPlaybackSegmentServe(
            docId: playbackDocID ?? docID,
            segmentKey: segmentKey,
            cacheHit: servedFromInflight,
            bytes: bytes.length,
            path: servedFromInflight ? 'inflight:$path' : path,
          );
          if (!servedFromInflight) {
            await cacheManager.writeSegment(
              docID,
              segmentKey,
              bytes,
              cacheOrigin: 'playback',
            );
          }
        }
      }

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('video', 'mp2t')
        ..headers.set('Access-Control-Allow-Origin', '*')
        ..headers.set('Cache-Control', 'public, max-age=31536000, immutable')
        ..headers.set('Connection', 'keep-alive')
        ..headers.contentLength = bytes.length
        ..add(bytes)
        ..close();
      if (docID != null && cacheManager != null) {
        final segmentKey = _extractSegmentKey(path, docID);
        if (segmentKey != null) {
          unawaited(
            _warmAdjacentPlaybackSegment(
              docId: docID,
              playbackDocId: playbackDocID,
              currentPath: path,
              currentSegmentKey: segmentKey,
              cacheManager: cacheManager,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[HLSProxy] CDN fetch failed for $cdnUrl: $e');
      request.response
        ..statusCode = HttpStatus.badGateway
        ..write('CDN fetch failed')
        ..close();
    } finally {
      if (ownsSegmentFetch) {
        _segmentFetchInFlight.remove(path);
      }
    }
  }

  /// CDN'den segment indir — deduplication için ayrılmış metod.
  Future<Uint8List> _fetchSegmentFromCDN(String cdnUrl) async {
    final response = await _httpClient
        .get(Uri.parse(cdnUrl), headers: _cdnHeaders)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw HttpException('CDN returned ${response.statusCode}');
    }
    return Uint8List.fromList(response.bodyBytes);
  }
}
