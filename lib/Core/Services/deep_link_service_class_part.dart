part of 'deep_link_service.dart';

class DeepLinkService extends GetxService with _DeepLinkServiceBasePart {
  @override
  void onClose() {
    _handleDeepLinkServiceClose(this);
    super.onClose();
  }
}
