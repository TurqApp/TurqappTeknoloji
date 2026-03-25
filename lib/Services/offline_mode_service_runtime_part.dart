part of 'offline_mode_service.dart';

extension OfflineModeServiceRuntimeX on OfflineModeService {
  void _handleOnInit() {
    _initialize();
  }

  void _handleOnClose() {
    _disposeOfflineMode();
  }

  String get _activeUid {
    final uid = CurrentUserService.instance.effectiveUserId;
    return uid.isEmpty ? 'guest' : uid;
  }

  String get _pendingActionsKey =>
      '${OfflineModeService._pendingActionsKeyPrefix}:$_activeUid';
  String get _deadLetterActionsKey =>
      '${OfflineModeService._deadLetterActionsKeyPrefix}:$_activeUid';
  String get _lastSyncAtKey =>
      '${OfflineModeService._lastSyncAtKeyPrefix}:$_activeUid';
  String get _processedCountKey =>
      '${OfflineModeService._processedCountKeyPrefix}:$_activeUid';
  String get _failedCountKey =>
      '${OfflineModeService._failedCountKeyPrefix}:$_activeUid';
}
