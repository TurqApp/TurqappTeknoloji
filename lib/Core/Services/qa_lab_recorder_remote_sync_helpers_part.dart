part of 'qa_lab_recorder.dart';

Map<String, dynamic> _qaLabDeviceInfoSnapshot() {
  return <String, dynamic>{
    'platform': defaultTargetPlatform.name,
    'buildMode': kReleaseMode
        ? 'release'
        : kProfileMode
            ? 'profile'
            : 'debug',
  };
}

Future<Map<String, dynamic>> _qaLabBuildExtendedDeviceInfo(
  QALabRecorder recorder,
) async {
  if (recorder._cachedExtendedDeviceInfo != null) {
    return Map<String, dynamic>.from(recorder._cachedExtendedDeviceInfo!);
  }
  final packageInfo = await PackageInfo.fromPlatform();
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo =
      GetPlatform.isAndroid ? await deviceInfo.androidInfo : null;
  final iosInfo = GetPlatform.isIOS ? await deviceInfo.iosInfo : null;
  final snapshot = <String, dynamic>{
    'package': <String, dynamic>{
      'appName': packageInfo.appName,
      'packageName': packageInfo.packageName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
    },
    'device': <String, dynamic>{
      if (androidInfo != null) 'manufacturer': androidInfo.manufacturer,
      if (androidInfo != null) 'model': androidInfo.model,
      if (androidInfo != null) 'sdkInt': androidInfo.version.sdkInt,
      if (iosInfo != null) 'name': iosInfo.name,
      if (iosInfo != null) 'model': iosInfo.model,
      if (iosInfo != null) 'systemVersion': iosInfo.systemVersion,
    },
  };
  recorder._cachedExtendedDeviceInfo = snapshot;
  return Map<String, dynamic>.from(snapshot);
}

Future<Map<String, dynamic>> _qaLabGetCachedExtendedDeviceInfo(
  QALabRecorder recorder,
) {
  final cached = recorder._cachedExtendedDeviceInfo;
  if (cached != null) {
    return Future<Map<String, dynamic>>.value(
      Map<String, dynamic>.from(cached),
    );
  }
  final inFlight = recorder._extendedDeviceInfoFuture;
  if (inFlight != null) {
    return inFlight;
  }
  final future = _qaLabBuildExtendedDeviceInfo(recorder);
  recorder._extendedDeviceInfoFuture = future.whenComplete(() {
    recorder._extendedDeviceInfoFuture = null;
  });
  return recorder._extendedDeviceInfoFuture!;
}

Map<String, dynamic> _qaLabRemoteSyncSnapshot(QALabRecorder recorder) {
  final uploader = QALabRemoteUploader.maybeFind();
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

Map<String, dynamic> _qaLabCompactNativePlaybackSnapshot(
  QALabRecorder recorder,
  Map<String, dynamic> snapshot,
) {
  if (snapshot.isEmpty) {
    return const <String, dynamic>{};
  }
  return <String, dynamic>{
    'platform': (snapshot['platform'] ?? '').toString(),
    'status': (snapshot['status'] ?? '').toString(),
    'errors': recorder._nativePlaybackErrors(snapshot),
    'active': snapshot['active'] == true,
    'firstFrameRendered': snapshot['firstFrameRendered'] == true,
    'isPlaybackExpected': snapshot['isPlaybackExpected'] == true,
    'isPlaying': snapshot['isPlaying'] == true,
    'isBuffering': snapshot['isBuffering'] == true,
    'stallCount': recorder._asInt(snapshot['stallCount']),
    'lastKnownPlaybackTime':
        recorder._asDouble(snapshot['lastKnownPlaybackTime']),
    'sampledAt': (snapshot['sampledAt'] ?? '').toString(),
    'trigger': (snapshot['trigger'] ?? '').toString(),
  };
}

Map<String, dynamic> _qaLabRemoteSnapshotDigest(Map<String, dynamic> snapshot) {
  final digest = <String, dynamic>{
    'currentRoute': (snapshot['currentRoute'] ?? '').toString(),
    'keys': snapshot.keys.take(24).map((item) => item.toString()).toList(),
  };
  for (final key in <String>[
    'auth',
    'feed',
    'short',
    'videoPlayback',
    'notifications',
    'chatConversation',
    'story',
    'pasaj',
    'profile',
    'settings',
    'upload',
    'explore',
  ]) {
    final value = snapshot[key];
    if (value is Map) {
      digest[key] = _qaLabSanitizeRemoteValue(value);
    }
  }
  return digest;
}

Object? _qaLabSanitizeRemoteValue(
  Object? value, {
  int depth = 0,
}) {
  if (value == null || value is num || value is bool) {
    return value;
  }
  if (value is String) {
    return value.length <= 260 ? value : '${value.substring(0, 257)}...';
  }
  if (value is DateTime) {
    return value.toUtc().toIso8601String();
  }
  if (value is Map) {
    if (depth >= 2) {
      return <String, dynamic>{
        'keys': value.keys.take(12).map((item) => item.toString()).toList(),
      };
    }
    final result = <String, dynamic>{};
    for (final entry in value.entries.take(12)) {
      final key = entry.key.toString();
      if (key == 'probe' || key.toLowerCase().contains('stack')) {
        continue;
      }
      result[key] = _qaLabSanitizeRemoteValue(entry.value, depth: depth + 1);
    }
    return result;
  }
  if (value is Iterable) {
    final items = value.take(7).map((item) {
      return _qaLabSanitizeRemoteValue(item, depth: depth + 1);
    }).toList(growable: true);
    if (value.length > 7) {
      items.add('...');
    }
    return items;
  }
  return value.toString();
}

String _qaLabRemoteIssueSignature({
  required String surface,
  required String code,
  required String rootCauseCategory,
  required String platform,
  required String buildMode,
}) {
  final base = <String>[
    surface.trim().toLowerCase(),
    code.trim().toLowerCase(),
    rootCauseCategory.trim().toLowerCase(),
    platform.trim().toLowerCase(),
    buildMode.trim().toLowerCase(),
  ].join('|');
  return _qaLabStableHash(base);
}

String _qaLabStableHash(String input) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(input)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
