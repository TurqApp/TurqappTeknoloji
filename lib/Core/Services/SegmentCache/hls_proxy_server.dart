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
part 'hls_proxy_server_runtime_part.dart';

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

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
