part of 'hls_proxy_server.dart';

const String _hlsProxyServerCdnOrigin = 'https://cdn.turqapp.com';
const String _hlsProxyServerAppIdentifier = 'turqapp-mobile';

HLSProxyServer? maybeFindHlsProxyServer() =>
    Get.isRegistered<HLSProxyServer>() ? Get.find<HLSProxyServer>() : null;

HLSProxyServer ensureHlsProxyServer({bool permanent = false}) =>
    maybeFindHlsProxyServer() ??
    Get.put(HLSProxyServer(), permanent: permanent);
