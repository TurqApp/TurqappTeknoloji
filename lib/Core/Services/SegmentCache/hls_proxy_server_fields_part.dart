part of 'hls_proxy_server.dart';

mixin _HlsProxyServerFieldsPart on GetxController {
  HttpServer? _server;
  final http.Client _httpClient = http.Client();
  int _pendingDownloadBytes = 0;

  final Map<String, Future<Uint8List>> _segmentFetchInFlight = {};

  int _port = 0;
  int get port => _port;
  String get baseUrl => 'http://127.0.0.1:$_port';

  bool _started = false;
  bool get isStarted => _started;
}
