part of 'hls_proxy_server.dart';

/// Lokal HTTP proxy — HLS isteklerini cache üzerinden serv eder.
///
/// Player `http://127.0.0.1:PORT/Posts/{docID}/hls/master.m3u8` URL'sine istek atar.
/// Proxy cache'te varsa disk'ten serv eder, yoksa CDN'den çeker + cache'ler + serv eder.
/// M3U8 playlist'lerde relative path kullanıldığı için rewriting gerekmez.
class HLSProxyServer extends GetxController with _HlsProxyServerFieldsPart {
  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
