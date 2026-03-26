part of 'offline_mode_service.dart';

class OfflineModeService extends GetxController {
  static final OfflineModeService instance = OfflineModeService._internal();
  OfflineModeService._internal();

  static OfflineModeService ensure() => _ensureOfflineModeService();

  static OfflineModeService? maybeFind() => _maybeFindOfflineModeService();

  static const int _maxRetryAttempts = 5;
  static const int _baseRetryDelayMs = 1500;
  static const int _maxRetryDelayMs = 5 * 60 * 1000;

  final _state = _OfflineModeServiceState();

  static const String _pendingActionsKeyPrefix = 'pending_actions';
  static const String _deadLetterActionsKeyPrefix =
      'pending_actions_dead_letter';
  static const String _lastSyncAtKeyPrefix = 'pending_actions_last_sync_at';
  static const String _processedCountKeyPrefix =
      'pending_actions_processed_count';
  static const String _failedCountKeyPrefix = 'pending_actions_failed_count';

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
