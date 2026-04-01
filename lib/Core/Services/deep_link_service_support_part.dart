part of 'deep_link_service.dart';

DeepLinkService _ensureDeepLinkService() {
  final existing = _maybeFindDeepLinkService();
  if (existing != null) return existing;
  return Get.put(DeepLinkService(), permanent: true);
}

DeepLinkService? _maybeFindDeepLinkService() {
  final isRegistered = Get.isRegistered<DeepLinkService>();
  if (!isRegistered) return null;
  return Get.find<DeepLinkService>();
}

void _handleDeepLinkServiceClose(DeepLinkService service) {
  _DeepLinkServiceRuntimeX(service).disposeRuntime();
}
