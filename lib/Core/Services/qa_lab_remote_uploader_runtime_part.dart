part of 'qa_lab_remote_uploader.dart';

class QALabRemoteUploaderRuntimePart {
  const QALabRemoteUploaderRuntimePart(this.uploader);

  final QALabRemoteUploader uploader;

  Future<void> scheduleUpload({
    required Map<String, dynamic> sessionDocument,
    List<Map<String, dynamic>> occurrences = const <Map<String, dynamic>>[],
    required String reason,
    bool immediate = false,
  }) async {
    if (!QALabMode.remoteUploadEnabled) {
      return;
    }
    final sessionId = (sessionDocument['sessionId'] ?? '').toString().trim();
    if (sessionId.isNotEmpty && sessionId != uploader._activeSessionId) {
      uploader._clearPermissionDeniedBlockForNewSession(sessionId);
      uploader._activeSessionId = sessionId;
      uploader._uploadedOccurrenceIds.clear();
    }
    uploader._pendingSessionDocument = uploader._sanitizeMap(sessionDocument);
    uploader._pendingReason = reason;
    for (final occurrence in occurrences) {
      final occurrenceId = (occurrence['occurrenceId'] ?? '').toString().trim();
      if (occurrenceId.isEmpty) {
        continue;
      }
      uploader._pendingOccurrences[occurrenceId] =
          uploader._sanitizeMap(occurrence);
    }

    uploader._debounceTimer?.cancel();
    if (immediate) {
      await uploader._flushPending();
      return;
    }
    uploader._debounceTimer = Timer(
      Duration(milliseconds: QALabMode.remoteUploadDebounceMs),
      () => unawaited(uploader._flushPending()),
    );
  }

  Future<void> flushNow() async {
    uploader._debounceTimer?.cancel();
    await uploader._flushPending();
  }

  void resetLocalState() {
    uploader._debounceTimer?.cancel();
    uploader._pendingSessionDocument = null;
    uploader._pendingReason = '';
    uploader._pendingOccurrences.clear();
    uploader._uploadedOccurrenceIds.clear();
    uploader._activeSessionId = '';
    uploader._permissionDeniedSessionId = '';
    uploader._permissionDeniedUntil = null;
    uploader.uploadCount.value = 0;
    uploader.uploadedOccurrenceCount.value = 0;
    uploader.lastSyncState.value = 'idle';
    uploader.lastSyncError.value = '';
    uploader.lastSyncReason.value = '';
    uploader.lastSyncedAt.value = null;
  }

  void onClose() {
    uploader._debounceTimer?.cancel();
    uploader._qaConfigSubscription?.cancel();
  }
}
