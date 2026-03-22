import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../network_awareness_service.dart';
import 'cache_manager.dart';
import 'hls_data_usage_probe.dart';
import 'm3u8_parser.dart';
import 'network_policy.dart';

part 'hls_proxy_server_playlist_part.dart';
part 'hls_proxy_server_segment_part.dart';

/// Lokal HTTP proxy — HLS isteklerini cache üzerinden serv eder.
///
/// Player `http://127.0.0.1:PORT/Posts/{docID}/hls/master.m3u8` URL'sine istek atar.
/// Proxy cache'te varsa disk'ten serv eder, yoksa CDN'den çeker + cache'ler + serv eder.
/// M3U8 playlist'lerde relative path kullanıldığı için rewriting gerekmez.
class HLSProxyServer extends GetxController {
  static HLSProxyServer? maybeFind() {
    final isRegistered = Get.isRegistered<HLSProxyServer>();
    if (!isRegistered) return null;
    return Get.find<HLSProxyServer>();
  }

  static HLSProxyServer ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(HLSProxyServer(), permanent: permanent);
  }

  static const String _cdnOrigin = 'https://cdn.turqapp.com';
  static const String _appIdentifier = 'turqapp-mobile';

  HttpServer? _server;
  final http.Client _httpClient = http.Client();
  int _pendingDownloadBytes = 0;

  /// Segment request deduplication — aynı segment için eş zamanlı CDN fetch'i engeller.
  final Map<String, Future<Uint8List>> _segmentFetchInFlight = {};

  int _port = 0;
  int get port => _port;
  String get baseUrl => 'http://127.0.0.1:$_port';

  bool _started = false;
  bool get isStarted => _started;

  /// Loopback'te dinamik port ile HTTP server başlat.
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

  /// Proxy'yi durdur.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _started = false;
  }

  /// CDN URL'yi proxy URL'ye çevir.
  /// Proxy başlamadıysa orijinal URL'yi döndür.
  String resolveUrl(String originalUrl) {
    if (!_started) return originalUrl;
    if (!originalUrl.contains('cdn.turqapp.com')) return originalUrl;
    return originalUrl.replaceFirst(_cdnOrigin, baseUrl);
  }

  // ──────────────────────────── Request Handling ────────────────────────────

  void _handleRequest(HttpRequest request) async {
    try {
      final path = request.uri.path; // e.g. /Posts/{docID}/hls/master.m3u8

      if (path.isEmpty || path == '/') {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not found')
          ..close();
        return;
      }

      // Path'ten docID çıkar: /Posts/{docID}/hls/...
      final docID = _extractDocID(path);

      if (_isPlaylistRequest(path)) {
        await _handlePlaylist(request, path, docID);
      } else {
        await _handleSegment(request, path, docID);
      }
    } catch (e) {
      debugPrint('[HLSProxy] Error handling ${request.uri}: $e');
      try {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write('Internal error')
          ..close();
      } catch (_) {}
    }
  }

  // ──────────────────────────── Helpers ────────────────────────────

  /// CDN isteklerine hotlink protection header'ları ekler.
  /// Cloudflare WAF kuralı bu header'ı doğrular:
  ///   X-Turq-App == "turqapp-mobile"
  ///   Referer == "https://cdn.turqapp.com/"
  Map<String, String> get _cdnHeaders => {
        'X-Turq-App': _appIdentifier,
        'Referer': '$_cdnOrigin/',
      };

  /// Path'ten docID çıkar: /Posts/{docID}/hls/...
  String? _extractDocID(String path) {
    // /Posts/{docID}/hls/...
    final match = RegExp(r'/Posts/([^/]+)/hls/').firstMatch(path);
    return match?.group(1);
  }

  /// Segment key çıkar: /Posts/{docID}/hls/{segmentKey}
  String? _extractSegmentKey(String path, String docID) {
    final prefix = '/Posts/$docID/hls/';
    final idx = path.indexOf(prefix);
    if (idx < 0) return null;
    return path.substring(idx + prefix.length);
  }

  bool _isPlaylistRequest(String path) {
    return path.endsWith('.m3u8');
  }

  SegmentCacheManager? _getCacheManager() {
    return SegmentCacheManager.maybeFind();
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

    // 1 MB üstü birikince persist et; çok sık SharedPreferences yazımını önler.
    const int oneMb = 1024 * 1024;
    final int downloadMb = _pendingDownloadBytes ~/ oneMb;
    if (downloadMb <= 0) return;

    _pendingDownloadBytes -= downloadMb * oneMb;

    final network = _getNetworkService();
    if (network != null) {
      unawaited(network.trackDataUsage(uploadMB: 0, downloadMB: downloadMb));
    }
  }

  @override
  void onClose() {
    // Kapanışta kalan byte'ları 1 MB'a yuvarlayıp kaydet.
    if (_pendingDownloadBytes > 0) {
      final int downloadMb = (_pendingDownloadBytes / (1024 * 1024)).ceil();
      final network = _getNetworkService();
      if (network != null) {
        unawaited(network.trackDataUsage(uploadMB: 0, downloadMB: downloadMb));
      }
      _pendingDownloadBytes = 0;
    }
    stop();
    _httpClient.close();
    super.onClose();
  }
}
