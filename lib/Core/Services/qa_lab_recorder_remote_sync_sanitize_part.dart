part of 'qa_lab_recorder.dart';

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
