part of 'hls_proxy_server.dart';

extension HlsProxyServerPlaylistPart on HLSProxyServer {
  /// M3U8 playlist isteği — cache'den veya CDN'den.
  Future<void> _handlePlaylist(
      HttpRequest request, String path, String? docID) async {
    final cacheManager = _getCacheManager();
    final probe = HlsDataUsageProbe.ensure();
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

    final cdnUrl = '$_cdnOrigin$path';
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
      final variantCdnUrl = '$_cdnOrigin$variantPath';

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
              '$_cdnOrigin$masterPath',
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
