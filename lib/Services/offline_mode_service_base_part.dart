part of 'offline_mode_service.dart';

abstract class _OfflineModeServiceBase extends GetxService {
  final _state = _OfflineModeServiceState();

  @override
  void onInit() {
    super.onInit();
    _handleOfflineModeServiceInit(this as OfflineModeService);
  }

  @override
  void onClose() {
    _handleOfflineModeServiceClose(this as OfflineModeService);
    super.onClose();
  }
}
