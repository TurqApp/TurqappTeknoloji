part of 'hls_proxy_server.dart';

/// Lokal HTTP proxy — HLS isteklerini cache üzerinden serv eder.
///
/// Player `http://127.0.0.1:PORT/Posts/{docID}/hls/master.m3u8` URL'sine istek atar.
/// Proxy cache'te varsa disk'ten serv eder, yoksa CDN'den çeker + cache'ler + serv eder.
/// M3U8 playlist'lerde relative path kullanıldığı için rewriting gerekmez.
class HLSProxyServer extends GetxController {
  HttpServer? _server;
  final http.Client _httpClient = http.Client();
  int _pendingDownloadBytes = 0;

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
