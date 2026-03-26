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

  String get _pendingActionsKey => '$_pendingActionsKeyPrefix:$_activeUid';
  String get _deadLetterActionsKey =>
      '$_deadLetterActionsKeyPrefix:$_activeUid';
  String get _lastSyncAtKey => '$_lastSyncAtKeyPrefix:$_activeUid';
  String get _processedCountKey => '$_processedCountKeyPrefix:$_activeUid';
  String get _failedCountKey => '$_failedCountKeyPrefix:$_activeUid';
}
