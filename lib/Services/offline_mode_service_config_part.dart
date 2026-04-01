part of 'offline_mode_service.dart';

const int _offlineModeMaxRetryAttempts = 5;
const int _offlineModeBaseRetryDelayMs = 1500;
const int _offlineModeMaxRetryDelayMs = 5 * 60 * 1000;

const String _pendingActionsKeyPrefix = 'pending_actions';
const String _deadLetterActionsKeyPrefix = 'pending_actions_dead_letter';
const String _lastSyncAtKeyPrefix = 'pending_actions_last_sync_at';
const String _processedCountKeyPrefix = 'pending_actions_processed_count';
const String _failedCountKeyPrefix = 'pending_actions_failed_count';
