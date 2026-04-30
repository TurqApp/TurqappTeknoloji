part of 'qa_lab_remote_uploader.dart';

Future<void> _qaLabRemoteUploaderFlushPending(
  QALabRemoteUploader uploader,
) async {
  if (uploader._syncInFlight) {
    return;
  }
  final sessionDocument = uploader._pendingSessionDocument;
  if (sessionDocument == null) {
    return;
  }
  if (Firebase.apps.isEmpty) {
    uploader.lastSyncState.value = 'awaiting_firebase';
    return;
  }
  final auth = uploader._authOverride ?? AppFirebaseAuth.instance;
  final user = auth.currentUser;
  if (user == null) {
    uploader.lastSyncState.value = 'awaiting_auth';
    return;
  }
  if (!await uploader._isRemoteGateEnabled()) {
    return;
  }

  final reason = uploader._pendingReason;
  final pendingOccurrences =
      uploader._pendingOccurrences.values.toList(growable: false);
  uploader._pendingSessionDocument = null;
  uploader._pendingOccurrences.clear();

  uploader._syncInFlight = true;
  uploader.lastSyncState.value = 'uploading';
  uploader.lastSyncError.value = '';
  uploader.lastSyncReason.value = reason;
  final sessionId =
      (sessionDocument['sessionId'] ?? '').toString().trim().isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : (sessionDocument['sessionId'] ?? '').toString().trim();

  try {
    final firestore = uploader._firestoreOverride ?? AppFirestore.instance;
    final scopeRef = firestore
        .collection(QALabMode.remoteCollectionName)
        .doc(QALabMode.remoteUploadScope);
    final sessionRef = scopeRef.collection('sessions').doc(sessionId);
    final batch = firestore.batch();
    final platform = (sessionDocument['platform'] ?? '').toString();
    final buildMode = (sessionDocument['buildMode'] ?? '').toString();
    final surface =
        ((sessionDocument['route'] as Map?)?['lastSurface'] ?? '').toString();

    batch.set(
      scopeRef,
      <String, dynamic>{
        'schemaVersion': 1,
        'scope': QALabMode.remoteUploadScope,
        'collection': QALabMode.remoteCollectionName,
        'lastSessionId': sessionId,
        'lastReason': reason,
        'lastPlatform': platform,
        'lastBuildMode': buildMode,
        'lastSurface': surface,
        'updatedAt': FieldValue.serverTimestamp(),
        'counters.totalUploads': FieldValue.increment(1),
        if (platform.isNotEmpty)
          'counters.byPlatform.${uploader._safeFieldKey(platform)}':
              FieldValue.increment(1),
        if (buildMode.isNotEmpty)
          'counters.byBuildMode.${uploader._safeFieldKey(buildMode)}':
              FieldValue.increment(1),
        if (surface.isNotEmpty)
          'counters.bySurface.${uploader._safeFieldKey(surface)}':
              FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );

    batch.set(
      sessionRef,
      <String, dynamic>{
        ...sessionDocument,
        'sessionId': sessionId,
        'updatedAt': FieldValue.serverTimestamp(),
        'remote': <String, dynamic>{
          ...((sessionDocument['remote'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{}),
          'scope': QALabMode.remoteUploadScope,
          'lastReason': reason,
          'lastSyncedAt': DateTime.now().toUtc().toIso8601String(),
          'uploadCount': uploader.uploadCount.value + 1,
        },
        'user': <String, dynamic>{
          'uid': user.uid,
          'email': user.email ?? '',
          'isAnonymous': user.isAnonymous,
        },
      },
      SetOptions(merge: true),
    );

    var uploadedNow = 0;
    for (final occurrence in pendingOccurrences) {
      final occurrenceId = (occurrence['occurrenceId'] ?? '').toString().trim();
      final signature = (occurrence['signature'] ?? '').toString().trim();
      if (occurrenceId.isEmpty ||
          signature.isEmpty ||
          uploader._uploadedOccurrenceIds.contains(occurrenceId)) {
        continue;
      }
      uploadedNow += 1;
      final issueRef = scopeRef.collection('issues').doc(signature);
      batch.set(
        issueRef,
        uploader._buildIssueAggregateMutation(
          sessionDocument: sessionDocument,
          occurrence: occurrence,
        ),
        SetOptions(merge: true),
      );
      batch.set(
        issueRef.collection('occurrences').doc(occurrenceId),
        <String, dynamic>{
          ...occurrence,
          'syncedAt': FieldValue.serverTimestamp(),
          'user': <String, dynamic>{
            'uid': user.uid,
            'email': user.email ?? '',
            'isAnonymous': user.isAnonymous,
          },
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
    uploader._uploadedOccurrenceIds.addAll(
      pendingOccurrences
          .map((item) => (item['occurrenceId'] ?? '').toString().trim())
          .where((item) => item.isNotEmpty),
    );
    uploader.uploadCount.value += 1;
    uploader.uploadedOccurrenceCount.value += uploadedNow;
    uploader.lastSyncedAt.value = DateTime.now();
    uploader._permissionDeniedUntil = null;
    uploader.lastSyncState.value = 'synced';
    uploader.lastSyncError.value = '';
  } catch (error, stackTrace) {
    uploader._pendingSessionDocument ??= sessionDocument;
    for (final occurrence in pendingOccurrences) {
      final occurrenceId = (occurrence['occurrenceId'] ?? '').toString().trim();
      if (occurrenceId.isEmpty) {
        continue;
      }
      uploader._pendingOccurrences.putIfAbsent(occurrenceId, () => occurrence);
    }
    if (error is FirebaseException && error.code == 'permission-denied') {
      uploader._permissionDeniedSessionId = sessionId;
      uploader._permissionDeniedUntil = null;
      uploader.remoteCollectionEnabled.value = false;
      uploader.lastGateCheckedAt.value = DateTime.now();
      uploader.lastSyncState.value = 'permission_denied';
      uploader.lastSyncReason.value = 'write_denied_session';
      uploader.lastSyncError.value = '$error';
      debugPrint(
        '[QA_LAB][REMOTE_PERMISSION_DENIED] Upload disabled for session $sessionId after write denial.\n$stackTrace',
      );
      return;
    }
    uploader.lastSyncState.value = 'error';
    uploader.lastSyncError.value = '$error';
    debugPrint(
      '[QA_LAB][REMOTE_SYNC_ERROR] ${error.runtimeType}: $error\n$stackTrace',
    );
  } finally {
    uploader._syncInFlight = false;
  }
}

Map<String, dynamic> _qaLabRemoteUploaderBuildIssueAggregateMutation(
  QALabRemoteUploader uploader, {
  required Map<String, dynamic> sessionDocument,
  required Map<String, dynamic> occurrence,
}) {
  final platform =
      (occurrence['platform'] ?? sessionDocument['platform'] ?? '').toString();
  final buildMode =
      (occurrence['buildMode'] ?? sessionDocument['buildMode'] ?? '')
          .toString();
  final surface = (occurrence['surface'] ?? '').toString();
  final severity = (occurrence['severity'] ?? '').toString();
  final eventCount = uploader._asInt(occurrence['eventCount']) <= 0
      ? 1
      : uploader._asInt(occurrence['eventCount']);
  return <String, dynamic>{
    'signature': (occurrence['signature'] ?? '').toString(),
    'code': (occurrence['code'] ?? '').toString(),
    'severity': severity,
    'surface': surface,
    'routeHint': (occurrence['route'] ?? '').toString(),
    'summary': (occurrence['summary'] ?? '').toString(),
    'message': (occurrence['message'] ?? '').toString(),
    'rootCauseCategory': (occurrence['rootCauseCategory'] ?? '').toString(),
    'rootCauseDetail': (occurrence['rootCauseDetail'] ?? '').toString(),
    'lastSessionId': (occurrence['sessionId'] ?? '').toString(),
    'lastOccurrenceId': (occurrence['occurrenceId'] ?? '').toString(),
    'lastDeviceModel': (occurrence['deviceModel'] ?? '').toString(),
    'lastPlatform': platform,
    'lastBuildMode': buildMode,
    'lastAppVersion': (occurrence['appVersion'] ?? '').toString(),
    'lastSeenAt': (occurrence['timestamp'] ?? '').toString(),
    'lastUploadAt': FieldValue.serverTimestamp(),
    'counters.totalSessions': FieldValue.increment(1),
    'counters.totalEvents': FieldValue.increment(eventCount),
    if (severity.isNotEmpty)
      'counters.bySeverity.${uploader._safeFieldKey(severity)}':
          FieldValue.increment(1),
    if (surface.isNotEmpty)
      'counters.bySurface.${uploader._safeFieldKey(surface)}':
          FieldValue.increment(1),
    if (platform.isNotEmpty)
      'counters.byPlatform.${uploader._safeFieldKey(platform)}':
          FieldValue.increment(1),
    if (buildMode.isNotEmpty)
      'counters.byBuildMode.${uploader._safeFieldKey(buildMode)}':
          FieldValue.increment(1),
  };
}
