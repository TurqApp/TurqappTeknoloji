part of 'qa_lab_recorder.dart';

Map<String, dynamic> _qaLabRemoteSyncSnapshot(QALabRecorder recorder) {
  final uploader = maybeFindQALabRemoteUploader();
  return <String, dynamic>{
    'enabled': QALabMode.remoteUploadEnabled,
    'scope': QALabMode.remoteUploadScope,
    if (uploader != null) 'state': uploader.lastSyncState.value,
    if (uploader != null) 'reason': uploader.lastSyncReason.value,
    if (uploader != null)
      'lastSyncedAt': uploader.lastSyncedAt.value?.toUtc().toIso8601String(),
    if (uploader != null) 'uploadCount': uploader.uploadCount.value,
    if (uploader != null)
      'uploadedOccurrenceCount': uploader.uploadedOccurrenceCount.value,
    if (uploader != null) 'lastError': uploader.lastSyncError.value,
  };
}

Map<String, dynamic> _qaLabRemoteRuntimeSummary(Map<String, dynamic> runtime) {
  const keys = <String>[
    'checkpointCount',
    'runtimeFindingCount',
    'blankSnapshotCount',
    'videoSessionStartCount',
    'videoFirstFrameCount',
    'cacheFailureCount',
    'jankEventCount',
    'worstFrameJankMs',
    'frameSampleCount',
    'frameCount',
    'slowFrameCount',
    'slowFrameRatio',
    'averageFrameTotalMs',
    'maxFrameTotalMs',
    'maxFrameBuildMs',
    'maxFrameRasterMs',
    'duplicateFeedTriggerCount',
    'duplicatePlaybackDispatchCount',
    'latestScrollDispatchLatencyMs',
    'latestScrollFirstFrameLatencyMs',
    'adRequestCount',
    'adLoadCount',
    'adFailureCount',
    'worstAdLoadMs',
    'nativePlaybackStatus',
    'nativePlaybackErrorCount',
    'nativePlaybackPlaying',
    'nativePlaybackBuffering',
    'nativePlaybackFirstFrame',
    'nativePlaybackStallCount',
  ];
  return <String, dynamic>{
    for (final key in keys)
      if (runtime.containsKey(key))
        key: _qaLabSanitizeRemoteValue(runtime[key]),
  };
}

Map<String, dynamic> _qaLabRemoteFindingSummary(
  QALabPinpointFinding finding,
) {
  return <String, dynamic>{
    'code': finding.code,
    'severity': finding.severity.name,
    'surface': finding.surface,
    'route': finding.route,
    'message': finding.message,
    'timestamp': finding.timestamp.toUtc().toIso8601String(),
    'context': _qaLabSanitizeRemoteValue(finding.context),
  };
}

String _qaLabRemoteOccurrenceSummary({
  required QALabPinpointFinding finding,
  QALabSurfaceAlertSummary? surfaceAlert,
}) {
  final rootCause = (surfaceAlert?.primaryRootCauseCategory ?? '').trim();
  final route = finding.route.trim().isEmpty ? '-' : finding.route.trim();
  final rootLabel = rootCause.isEmpty ? '' : ' [$rootCause]';
  return '${finding.surface} $route :: ${finding.code}$rootLabel :: ${finding.message}';
}

List<Map<String, dynamic>> _qaLabRemoteTimelineHighlights(
  QALabRecorder recorder, {
  String? surface,
  String? route,
  int limit = 8,
}) {
  final filtered = recorder.timelineEvents.where((event) {
    if (surface != null && surface.trim().isNotEmpty) {
      if (event.surface.trim() != surface.trim()) {
        return false;
      }
    }
    if (route != null && route.trim().isNotEmpty) {
      if (event.route.trim() != route.trim()) {
        return false;
      }
    }
    return true;
  }).toList(growable: false);
  final slice = filtered.length <= limit
      ? filtered
      : filtered.sublist(filtered.length - limit);
  return slice
      .map(
        (event) => <String, dynamic>{
          'category': event.category,
          'code': event.code,
          'surface': event.surface,
          'route': event.route,
          'timestamp': event.timestamp.toUtc().toIso8601String(),
          'metadata': _qaLabSanitizeRemoteValue(event.metadata),
        },
      )
      .toList(growable: false);
}
