part of 'hls_proxy_server.dart';

const String _hlsProxyServerCdnOrigin = 'https://cdn.turqapp.com';
const String _hlsProxyServerAppIdentifier = 'turqapp-mobile';

HLSProxyServer? maybeFindHlsProxyServer() {
  final isRegistered = Get.isRegistered<HLSProxyServer>();
  if (!isRegistered) return null;
  return Get.find<HLSProxyServer>();
}

HLSProxyServer ensureHlsProxyServer({bool permanent = false}) {
  final existing = maybeFindHlsProxyServer();
  if (existing != null) return existing;
  return Get.put(HLSProxyServer(), permanent: permanent);
}
