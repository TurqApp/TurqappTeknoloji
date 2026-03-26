part of 'offline_mode_service.dart';

class OfflineModeService extends GetxController {
  static final OfflineModeService instance = OfflineModeService._internal();
  OfflineModeService._internal();

  final _state = _OfflineModeServiceState();

  @override
  void onInit() {
    super.onInit();
    _handleOfflineModeServiceInit(this);
  }

  @override
  void onClose() {
    _handleOfflineModeServiceClose(this);
    super.onClose();
  }
}
