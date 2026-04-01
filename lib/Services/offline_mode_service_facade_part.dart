part of 'offline_mode_service.dart';

OfflineModeService ensureOfflineModeService() => _ensureOfflineModeService();

OfflineModeService? maybeFindOfflineModeService() =>
    _maybeFindOfflineModeService();

OfflineModeService _ensureOfflineModeService() =>
    _maybeFindOfflineModeService() ??
    Get.put(OfflineModeService.instance, permanent: true);

OfflineModeService? _maybeFindOfflineModeService() =>
    Get.isRegistered<OfflineModeService>()
        ? Get.find<OfflineModeService>()
        : null;

void _handleOfflineModeServiceInit(OfflineModeService service) {
  service._handleOnInit();
}

void _handleOfflineModeServiceClose(OfflineModeService service) {
  service._handleOnClose();
}
