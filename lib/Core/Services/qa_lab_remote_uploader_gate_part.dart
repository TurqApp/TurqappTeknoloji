part of 'qa_lab_remote_uploader.dart';

bool _qaLabRemoteUploaderAsBool(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase() ?? '';
  if (normalized.isEmpty) return fallback;
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}

Future<bool> _qaLabRemoteUploaderIsRemoteGateEnabled(
  QALabRemoteUploader uploader,
) async {
  if (IntegrationTestMode.enabled) {
    return false;
  }
  uploader._ensureAdminConfigSubscription();
  final now = DateTime.now();
  if (uploader._permissionDeniedSessionId.isNotEmpty &&
      uploader._permissionDeniedSessionId == uploader._activeSessionId) {
    return false;
  }
  if (uploader._permissionDeniedUntil != null &&
      now.isBefore(uploader._permissionDeniedUntil!)) {
    return false;
  }
  if (uploader._lastGateRefreshAt != null &&
      now.difference(uploader._lastGateRefreshAt!) <
          const Duration(seconds: 20)) {
    return uploader.remoteCollectionEnabled.value;
  }
  uploader._lastGateRefreshAt = now;
  try {
    final qaDoc = await ensureConfigRepository().getAdminConfigDoc(
      'qa',
      preferCache: true,
      forceRefresh: false,
      ttl: const Duration(seconds: 20),
    );
    uploader._applyRemoteGateState(
      qaEnabled: _qaLabRemoteUploaderAsBool(
        qaDoc?['qaEnabled'],
        fallback: false,
      ),
      source: 'config_fetch',
    );
    return uploader.remoteCollectionEnabled.value;
  } catch (error, stackTrace) {
    uploader.lastGateCheckedAt.value = DateTime.now();
    uploader.lastSyncState.value = 'gate_error';
    uploader.lastSyncError.value = '$error';
    debugPrint(
      '[QA_LAB][REMOTE_GATE_ERROR] ${error.runtimeType}: $error\n$stackTrace',
    );
    return false;
  }
}

void _qaLabRemoteUploaderEnsureAdminConfigSubscription(
  QALabRemoteUploader uploader,
) {
  if (IntegrationTestMode.enabled) {
    return;
  }
  if (Firebase.apps.isEmpty) {
    return;
  }
  uploader._qaConfigSubscription ??= ensureConfigRepository()
      .watchAdminConfigDoc(
    'qa',
    ttl: const Duration(seconds: 20),
  )
      .listen(
    (doc) {
      uploader._applyRemoteGateState(
        qaEnabled: _qaLabRemoteUploaderAsBool(
          doc['qaEnabled'],
          fallback: false,
        ),
        source: 'qa_watch',
      );
    },
    onError: (Object error, StackTrace stackTrace) {
      uploader.lastGateCheckedAt.value = DateTime.now();
      uploader.lastSyncState.value = 'gate_error';
      uploader.lastSyncError.value = '$error';
      debugPrint(
        '[QA_LAB][REMOTE_GATE_WATCH_ERROR] ${error.runtimeType}: $error\n$stackTrace',
      );
    },
  );
}

void _qaLabRemoteUploaderApplyRemoteGateState(
  QALabRemoteUploader uploader, {
  required bool qaEnabled,
  required String source,
}) {
  uploader.remoteCollectionEnabled.value = qaEnabled;
  uploader.lastGateCheckedAt.value = DateTime.now();
  if (qaEnabled) {
    uploader._permissionDeniedUntil = null;
    if (uploader.lastSyncState.value == 'disabled_by_admin' ||
        (uploader.lastSyncState.value == 'permission_denied' &&
            uploader._permissionDeniedSessionId.isEmpty)) {
      uploader.lastSyncState.value = 'idle';
      uploader.lastSyncError.value = '';
    }
    return;
  }
  uploader._pendingSessionDocument = null;
  uploader._pendingOccurrences.clear();
  uploader.lastSyncState.value = 'disabled_by_admin';
  uploader.lastSyncReason.value = source;
  uploader.lastSyncError.value = '';
}

Map<String, dynamic> _qaLabRemoteUploaderSanitizeMap(
  Map<String, dynamic> input,
) {
  return input.map(
    (key, value) => MapEntry(key, _qaLabRemoteUploaderSanitizeValue(value)),
  );
}

Object? _qaLabRemoteUploaderSanitizeValue(Object? value) {
  if (value == null || value is num || value is bool || value is String) {
    return value;
  }
  if (value is DateTime) {
    return value.toUtc().toIso8601String();
  }
  if (value is Map) {
    return value.map(
      (key, nested) => MapEntry(
        key.toString(),
        _qaLabRemoteUploaderSanitizeValue(nested),
      ),
    );
  }
  if (value is Iterable) {
    return value.map(_qaLabRemoteUploaderSanitizeValue).toList(growable: false);
  }
  return value.toString();
}

String _qaLabRemoteUploaderSafeFieldKey(String input) {
  final normalized = input.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  if (normalized.isEmpty) {
    return 'unknown';
  }
  return normalized;
}

int _qaLabRemoteUploaderAsInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

void _qaLabRemoteUploaderClearPermissionDeniedBlockForNewSession(
  QALabRemoteUploader uploader,
  String sessionId,
) {
  if (uploader._permissionDeniedSessionId.isEmpty ||
      uploader._permissionDeniedSessionId == sessionId) {
    return;
  }
  uploader._permissionDeniedSessionId = '';
  uploader._permissionDeniedUntil = null;
  uploader._lastGateRefreshAt = null;
  if (uploader.lastSyncState.value == 'permission_denied') {
    uploader.lastSyncState.value = 'idle';
    uploader.lastSyncError.value = '';
  }
}
