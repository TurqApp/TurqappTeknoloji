part of 'hls_proxy_server.dart';

/// Lokal HTTP proxy - HLS isteklerini cache uzerinden serv eder.
///
/// Player `http://127.0.0.1:PORT/Posts/{docID}/hls/master.m3u8` URL'sine istek atar.
/// Proxy cache'te varsa disk'ten serv eder, yoksa CDN'den ceker + cache'ler + serv eder.
/// M3U8 playlist'lerde relative path kullanildigi icin rewriting gerekmez.
class HLSProxyServer extends GetxController with _HlsProxyServerFieldsPart {
  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}

extension HLSProxyServerRuntimeX on HLSProxyServer {
  Future<void> start() async {
    if (_started) return;
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;
      _started = true;
      debugPrint('[HLSProxy] Started on port $_port');
      _server!.listen(_handleRequest);
    } catch (e) {
      debugPrint('[HLSProxy] Failed to start: $e');
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _started = false;
  }

  String resolveUrl(String originalUrl) {
    if (!_started) return originalUrl;
    if (!originalUrl.contains('cdn.turqapp.com')) return originalUrl;
    if (_getCacheManager() == null) return originalUrl;
    return originalUrl.replaceFirst(_hlsProxyServerCdnOrigin, baseUrl);
  }

  void _handleRequest(HttpRequest request) async {
    try {
      final path = request.uri.path;

      if (path.isEmpty || path == '/') {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not found')
          ..close();
        return;
      }

      final docID = _extractDocID(path);

      if (_isPlaylistRequest(path)) {
        await _handlePlaylist(request, path, docID);
      } else {
        await _handleSegment(request, path, docID);
      }
    } catch (e, stackTrace) {
      debugPrint('[HLSProxy] Error handling ${request.uri}: $e');
      debugPrintStack(
        label: '[HLSProxy] Error stack for ${request.uri}',
        stackTrace: stackTrace,
      );
      try {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write('Internal error')
          ..close();
      } catch (_) {}
    }
  }

  Map<String, String> get _cdnHeaders => {
        'X-Turq-App': _hlsProxyServerAppIdentifier,
        'Referer': '$_hlsProxyServerCdnOrigin/',
      };

  String? _extractDocID(String path) {
    final match = RegExp(r'/Posts/([^/]+)/hls/').firstMatch(path);
    return match?.group(1);
  }

  String? _extractSegmentKey(String path, String docID) {
    final prefix = '/Posts/$docID/hls/';
    final idx = path.indexOf(prefix);
    if (idx < 0) return null;
    return path.substring(idx + prefix.length);
  }

  bool _isPlaylistRequest(String path) => path.endsWith('.m3u8');

  SegmentCacheManager? _getCacheManager() {
    final cache = SegmentCacheManager.maybeFind();
    if (cache == null || !cache.isReady) return null;
    return cache;
  }

  NetworkAwarenessService? _getNetworkService() {
    try {
      final existing = NetworkAwarenessService.maybeFind();
      if (existing != null) {
        return existing;
      }
      final service = NetworkAwarenessService.ensure();
      debugPrint('[HLSProxy] NetworkAwarenessService auto-registered');
      return service;
    } catch (e) {
      debugPrint('[HLSProxy] Failed to auto-register network service: $e');
      return null;
    }
  }

  void _trackDownloadBytes(int bytes) {
    if (bytes <= 0) return;
    _pendingDownloadBytes += bytes;

    const int oneMb = 1024 * 1024;
    final int downloadMb = _pendingDownloadBytes ~/ oneMb;
    if (downloadMb <= 0) return;

    _pendingDownloadBytes -= downloadMb * oneMb;

    final network = _getNetworkService();
    if (network != null) {
      unawaited(network.trackDataUsage(uploadMB: 0, downloadMB: downloadMb));
    }
  }

  void _handleOnClose() {
    if (_pendingDownloadBytes > 0) {
      final int downloadMb = (_pendingDownloadBytes / (1024 * 1024)).ceil();
      final network = _getNetworkService();
      if (network != null) {
        unawaited(network.trackDataUsage(uploadMB: 0, downloadMB: downloadMb));
      }
      _pendingDownloadBytes = 0;
    }
    unawaited(stop());
    _httpClient.close();
  }
}
