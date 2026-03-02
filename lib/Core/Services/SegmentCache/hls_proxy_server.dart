import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../network_awareness_service.dart';
import 'cache_manager.dart';
import 'm3u8_parser.dart';
import 'network_policy.dart';

/// Lokal HTTP proxy — HLS isteklerini cache üzerinden serv eder.
///
/// Player `http://127.0.0.1:PORT/Posts/{docID}/hls/master.m3u8` URL'sine istek atar.
/// Proxy cache'te varsa disk'ten serv eder, yoksa CDN'den çeker + cache'ler + serv eder.
/// M3U8 playlist'lerde relative path kullanıldığı için rewriting gerekmez.
class HLSProxyServer extends GetxController {
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

  /// M3U8 playlist isteği — cache'den veya CDN'den.
  Future<void> _handlePlaylist(
      HttpRequest request, String path, String? docID) async {
    final cacheManager = _getCacheManager();
    final relativePath = path.startsWith('/') ? path.substring(1) : path;

    // Disk cache kontrol
    final cached = cacheManager?.getPlaylistFile(relativePath);
    if (cached != null) {
      try {
        final content = await cached.readAsString();
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType('application', 'vnd.apple.mpegurl')
          ..headers.set('Access-Control-Allow-Origin', '*')
          ..headers.set('Connection', 'keep-alive')
          ..write(content)
          ..close();
        return;
      } catch (_) {
        // Disk okuma hatası — CDN'den çek
      }
    }

    // CDN'den çek — playlist küçük, cellular'da da izin ver
    if (!CacheNetworkPolicy.canFetchPlaylist) {
      request.response
        ..statusCode = HttpStatus.serviceUnavailable
        ..write('Offline — playlist not cached')
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

      // Disk'e cache'le
      if (cacheManager != null) {
        unawaited(cacheManager.writePlaylist(relativePath, content));

        // Master playlist ise variant + segment bilgilerini çıkar
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

  /// Segment isteği (.ts) — cache'den veya CDN'den.
  Future<void> _handleSegment(
      HttpRequest request, String path, String? docID) async {
    final cacheManager = _getCacheManager();
    final metrics = cacheManager?.metrics;

    if (docID != null && cacheManager != null) {
      // Segment key: docID'den sonraki kısım, örn. "720p/segment_0.ts"
      final segmentKey = _extractSegmentKey(path, docID);

      if (segmentKey != null) {
        // Cache hit kontrol
        final cached = cacheManager.getSegmentFile(docID, segmentKey);
        if (cached != null) {
          try {
            final bytes = await cached.readAsBytes();
            metrics?.recordHit(bytes.length);
            cacheManager.touchEntry(docID);

            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType('video', 'mp2t')
              ..headers.set('Access-Control-Allow-Origin', '*')
              ..headers.set('Cache-Control', 'public, max-age=31536000, immutable')
              ..headers.set('Connection', 'keep-alive')
              ..headers.contentLength = bytes.length
              ..add(bytes)
              ..close();
            return;
          } catch (_) {
            // Disk'te dosya yok/bozuk — cache miss gibi davran, CDN'den çek
          }
        }
      }
    }

    // Cache miss — Sadece Wi-Fi'de CDN'den çek, cellular/offline'da çekme
    if (!CacheNetworkPolicy.canFetchOnDemand) {
      request.response
        ..statusCode = HttpStatus.serviceUnavailable
        ..write('Not on Wi-Fi — segment not cached')
        ..close();
      return;
    }

    final cdnUrl = '$_cdnOrigin$path';
    try {
      // Deduplication: aynı segment için zaten CDN fetch varsa onu bekle
      final existing = _segmentFetchInFlight[path];
      final Uint8List bytes;
      if (existing != null) {
        bytes = await existing;
      } else {
        final future = _fetchSegmentFromCDN(cdnUrl);
        _segmentFetchInFlight[path] = future;
        try {
          bytes = await future;
        } finally {
          _segmentFetchInFlight.remove(path);
        }
      }

      metrics?.recordMiss(bytes.length);
      _trackDownloadBytes(bytes.length);

      // Disk'e cache'le
      if (docID != null && cacheManager != null) {
        final segmentKey = _extractSegmentKey(path, docID);
        if (segmentKey != null) {
          unawaited(cacheManager.writeSegment(docID, segmentKey, bytes));
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
    } catch (e) {
      debugPrint('[HLSProxy] CDN fetch failed for $cdnUrl: $e');
      request.response
        ..statusCode = HttpStatus.badGateway
        ..write('CDN fetch failed')
        ..close();
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

  /// CDN'den segment indir — deduplication için ayrılmış metod.
  Future<Uint8List> _fetchSegmentFromCDN(String cdnUrl) async {
    final response = await _httpClient
        .get(Uri.parse(cdnUrl), headers: _cdnHeaders)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw HttpException('CDN returned ${response.statusCode}');
    }
    return response.bodyBytes;
  }

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
    try {
      return Get.find<SegmentCacheManager>();
    } catch (_) {
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

    try {
      final network = Get.find<NetworkAwarenessService>();
      unawaited(network.trackDataUsage(uploadMB: 0, downloadMB: downloadMb));
    } catch (_) {}
  }

  /// Master playlist parse edip entry meta bilgisini güncelle.
  void _parseMasterAndUpdateMeta(
      String docID, String masterContent, String masterPath) {
    try {
      final variants = M3U8Parser.parseVariants(masterContent);
      if (variants.isEmpty) return;

      // En iyi variant'ın playlist'ini arka planda çekip segment sayısını bul
      final best = M3U8Parser.bestVariant(variants);
      if (best == null) return;

      // Variant URI'si relative — master playlist path'ine göre çözümle
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
            // Variant playlist'i de cache'le
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

  @override
  void onClose() {
    // Kapanışta kalan byte'ları 1 MB'a yuvarlayıp kaydet.
    if (_pendingDownloadBytes > 0) {
      final int downloadMb = (_pendingDownloadBytes / (1024 * 1024)).ceil();
      try {
        final network = Get.find<NetworkAwarenessService>();
        unawaited(network.trackDataUsage(uploadMB: 0, downloadMB: downloadMb));
      } catch (_) {}
      _pendingDownloadBytes = 0;
    }
    stop();
    _httpClient.close();
    super.onClose();
  }
}
