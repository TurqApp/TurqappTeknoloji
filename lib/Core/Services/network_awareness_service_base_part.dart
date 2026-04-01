part of 'network_awareness_service.dart';

abstract class _NetworkAwarenessServiceBase extends GetxService {
  final _state = _NetworkAwarenessServiceState();

  @override
  void onInit() {
    super.onInit();
    _handleNetworkAwarenessInit(this as NetworkAwarenessService);
  }

  @override
  void onClose() {
    _handleNetworkAwarenessClose(this as NetworkAwarenessService);
    super.onClose();
  }
}
