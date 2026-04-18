part of 'hls_proxy_server.dart';

extension HlsProxyServerPlaylistPart on HLSProxyServer {
  static const int _shortStartupWarmFutureSegmentCount = 2;

  bool _shouldWarmShortStartupSegments(String docID) {
    bool matchesShortHandle(String? handleKey) {
      final trimmed = handleKey?.trim() ?? '';
      if (!trimmed.startsWith('short:')) return false;
      return HlsSegmentPolicy.normalizeDocId(trimmed) == docID;
    }

    final manager = maybeFindVideoStateManager();
    if (manager == null) return false;
    return matchesShortHandle(manager.currentPlayingDocID) ||
        matchesShortHandle(manager.targetPlaybackDocID);
  }

  String _playlistHlsRoot(String playlistRelativePath) {
    final hlsIndex = playlistRelativePath.indexOf('/hls/');
    if (hlsIndex < 0) {
      return playlistRelativePath.substring(
        0,
        playlistRelativePath.lastIndexOf('/') + 1,
      );
    }
    return playlistRelativePath.substring(0, hlsIndex + '/hls/'.length);
  }

  Future<void> _warmShortStartupSegmentsFromVariantPlaylist({
    required String docID,
    required String playlistPath,
    required String playlistContent,
    required SegmentCacheManager cacheManager,
  }) async {
    if (!_shouldWarmShortStartupSegments(docID)) return;
    if (!_canFetchSegmentOnDemandForDoc(docID)) return;

    final segmentUris = M3U8Parser.segmentUris(playlistContent);
    if (segmentUris.length < 2) return;

    final relativePath =
        playlistPath.startsWith('/') ? playlistPath.substring(1) : playlistPath;
    final lastSlashIndex = relativePath.lastIndexOf('/');
    if (lastSlashIndex < 0) return;

    final playlistDir = relativePath.substring(0, lastSlashIndex + 1);
    final hlsRoot = _playlistHlsRoot(relativePath);
    final entry = cacheManager.getEntry(docID);
    final currentSegmentIndex =
        HlsSegmentPolicy.estimateCurrentSegmentFromProgress(
              progress: entry?.watchProgress ?? 0.0,
              totalSegments: segmentUris.length,
            ) -
            1;
    final safeCurrentIndex =
        currentSegmentIndex.clamp(0, segmentUris.length - 1);
    final safeStartIndex =
        (safeCurrentIndex + 1).clamp(0, segmentUris.length - 1);
    if (safeStartIndex <= safeCurrentIndex) return;
    final warmUntil = (safeStartIndex + _shortStartupWarmFutureSegmentCount)
        .clamp(0, segmentUris.length);

    final targetIndices = <int>[];
    for (var index = safeStartIndex; index < warmUntil; index++) {
      targetIndices.add(index);
    }
    if (targetIndices.isEmpty) return;

    claimExternalOnDemandFetchForDoc(docID);
    try {
      for (final index in targetIndices) {
        final uri = segmentUris[index];
        final requestPath =
            '/${playlistDir.startsWith('/') ? playlistDir.substring(1) : playlistDir}$uri';
        final segmentKey = '${playlistDir.replaceFirst(hlsRoot, '')}$uri';
        if (cacheManager.getSegmentFile(docID, segmentKey) != null) {
          continue;
        }

        final existing = _segmentFetchInFlight[requestPath];
        final bytes = existing != null
            ? await existing
            : await () async {
                final future =
                    _fetchSegmentFromCDN('$_hlsProxyServerCdnOrigin$requestPath');
                _segmentFetchInFlight[requestPath] = future;
                try {
                  return await future;
                } finally {
                  _segmentFetchInFlight.remove(requestPath);
                }
              }();

        if (!_canFetchSegmentOnDemandForDoc(docID)) return;
        await cacheManager.writeSegment(docID, segmentKey, bytes);
        _logPlaybackSegmentServe(
          docId: docID,
          segmentKey: segmentKey,
          cacheHit: false,
          bytes: bytes.length,
          path: requestPath,
        );
      }
    } finally {
      releaseExternalOnDemandFetchForDoc(docID);
    }
  }

  /// M3U8 playlist isteği — cache'den veya CDN'den.
  Future<void> _handlePlaylist(
      HttpRequest request, String path, String? docID) async {
    final cacheManager = _getCacheManager();
    final probe = ensureHlsDataUsageProbe();
    final relativePath = path.startsWith('/') ? path.substring(1) : path;

    final cached = cacheManager?.getPlaylistFile(relativePath);
    if (cached != null) {
      try {
        final content = await cached.readAsString();
        if (docID != null) {
          if (M3U8Parser.isMasterPlaylist(content)) {
            probe.recordMasterPlaylist(
              docId: docID,
              path: path,
              content: content,
              source: HlsTrafficSource.playback,
              cacheHit: true,
            );
          } else {
            probe.recordVariantPlaylist(
              docId: docID,
              path: path,
              content: content,
              source: HlsTrafficSource.playback,
              cacheHit: true,
            );
          }
        }
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType =
              ContentType('application', 'vnd.apple.mpegurl')
          ..headers.set('Access-Control-Allow-Origin', '*')
          ..headers.set('Connection', 'keep-alive')
          ..write(content)
          ..close();
        if (docID != null &&
            cacheManager != null &&
            !M3U8Parser.isMasterPlaylist(content)) {
          unawaited(
            _warmShortStartupSegmentsFromVariantPlaylist(
              docID: docID,
              playlistPath: path,
              playlistContent: content,
              cacheManager: cacheManager,
            ),
          );
        }
        return;
      } catch (_) {}
    }

    if (!CacheNetworkPolicy.canFetchPlaylist) {
      request.response
        ..statusCode = HttpStatus.serviceUnavailable
        ..write(CacheNetworkPolicy.playlistFetchBlockedReason)
        ..close();
      return;
    }

    final cdnUrl = '$_hlsProxyServerCdnOrigin$path';
    try {
      final response = await _httpClient
          .get(Uri.parse(cdnUrl), headers: _cdnHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        request.response
          ..statusCode = response.statusCode
          ..write(response.body)
          ..close();
        return;
      }

      final content = response.body;
      await probe.maybeApplyDebugDelay(
        isPlaylist: true,
        source: HlsTrafficSource.playback,
      );
      if (docID != null) {
        if (M3U8Parser.isMasterPlaylist(content)) {
          probe.recordMasterPlaylist(
            docId: docID,
            path: path,
            content: content,
            source: HlsTrafficSource.playback,
            cacheHit: false,
          );
        } else {
          probe.recordVariantPlaylist(
            docId: docID,
            path: path,
            content: content,
            source: HlsTrafficSource.playback,
            cacheHit: false,
          );
        }
      }

      if (cacheManager != null) {
        unawaited(cacheManager.writePlaylist(relativePath, content));

        if (docID != null && M3U8Parser.isMasterPlaylist(content)) {
          _parseMasterAndUpdateMeta(docID, content, path);
        }
      }

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('application', 'vnd.apple.mpegurl')
        ..headers.set('Access-Control-Allow-Origin', '*')
        ..write(content)
        ..close();
      if (docID != null && !M3U8Parser.isMasterPlaylist(content)) {
        final readyCacheManager = cacheManager ?? _getCacheManager();
        if (readyCacheManager != null) {
          unawaited(
            _warmShortStartupSegmentsFromVariantPlaylist(
              docID: docID,
              playlistPath: path,
              playlistContent: content,
              cacheManager: readyCacheManager,
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
    }
  }

  /// Master playlist parse edip entry meta bilgisini güncelle.
  void _parseMasterAndUpdateMeta(
      String docID, String masterContent, String masterPath) {
    try {
      final variants = M3U8Parser.parseVariants(masterContent);
      if (variants.isEmpty) return;

      final best = M3U8Parser.bestVariant(variants);
      if (best == null) return;

      final masterDir =
          masterPath.substring(0, masterPath.lastIndexOf('/') + 1);
      final variantPath = '$masterDir${best.uri}';
      final variantCdnUrl = '$_hlsProxyServerCdnOrigin$variantPath';

      _httpClient
          .get(Uri.parse(variantCdnUrl), headers: _cdnHeaders)
          .timeout(const Duration(seconds: 10))
          .then((response) {
        if (response.statusCode == 200) {
          final segments = M3U8Parser.parseSegments(response.body);
          final cacheManager = _getCacheManager();
          if (cacheManager != null) {
            cacheManager.updateEntryMeta(
              docID,
              '$_hlsProxyServerCdnOrigin$masterPath',
              segments.length,
            );
            final relativePath = variantPath.startsWith('/')
                ? variantPath.substring(1)
                : variantPath;
            cacheManager.writePlaylist(relativePath, response.body);
          }
        }
      }).catchError((_) {});
    } catch (e) {
      debugPrint('[HLSProxy] Master parse error: $e');
    }
  }
}
