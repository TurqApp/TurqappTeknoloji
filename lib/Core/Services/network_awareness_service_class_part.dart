part of 'network_awareness_service.dart';

class NetworkAwarenessService extends GetxController {
  static NetworkAwarenessService? maybeFind() =>
      _maybeFindNetworkAwarenessService();

  static NetworkAwarenessService ensure() => _ensureNetworkAwarenessService();

  final _state = _NetworkAwarenessServiceState();

  @override
  void onInit() {
    super.onInit();
    _handleNetworkAwarenessInit(this);
  }

  @override
  void onClose() {
    _handleNetworkAwarenessClose(this);
    super.onClose();
  }
}
