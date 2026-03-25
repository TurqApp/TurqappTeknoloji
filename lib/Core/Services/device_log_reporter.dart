import 'dart:convert';

class DeviceLogIssue {
  const DeviceLogIssue({
    required this.code,
    required this.severity,
    required this.tag,
    required this.message,
    required this.count,
    required this.sampleLine,
  });

  final String code;
  final String severity;
  final String tag;
  final String message;
  final int count;
  final String sampleLine;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      'severity': severity,
      'tag': tag,
      'message': message,
      'count': count,
      'sampleLine': sampleLine,
      'type': 'device_log',
    };
  }
}

class DeviceLogObservation {
  const DeviceLogObservation({
    required this.code,
    required this.tag,
    required this.message,
    required this.count,
  });

  final String code;
  final String tag;
  final String message;
  final int count;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      'tag': tag,
      'message': message,
      'count': count,
    };
  }
}

class DeviceLogReport {
  const DeviceLogReport({
    required this.source,
    required this.summary,
    required this.metrics,
    required this.issues,
    required this.observations,
  });

  final Map<String, dynamic> source;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> metrics;
  final List<DeviceLogIssue> issues;
  final List<DeviceLogObservation> observations;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'source': source,
      'summary': summary,
      'metrics': metrics,
      'issues': issues.map((issue) => issue.toJson()).toList(growable: false),
      'observations': observations
          .map((observation) => observation.toJson())
          .toList(growable: false),
    };
  }
}

class DeviceLogReporter {
  const DeviceLogReporter._();

  static const int _stagnantPlaybackPositionThreshold = 10;

  static DeviceLogReport buildReport(
    String rawLog, {
    required String deviceId,
    required String platform,
    String packageName = '',
    String processId = '',
  }) {
    final lines = const LineSplitter()
        .convert(rawLog)
        .map((line) => line.trimRight())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    final issueBuckets = <String, _MutableLogEntry>{};
    final observationBuckets = <String, _MutableLogEntry>{};
    final playbackPositionBuckets = <String, _MutableLogEntry>{};
    int? firstFrameTtffMs;
    var firstFrameRenderedCount = 0;
    var playerReadyCount = 0;
    var playbackStartedCount = 0;
    var frameAcquireFenceMissCount = 0;
    var chromaSitingWarningCount = 0;
    var pesStartCodeWarningCount = 0;

    for (final line in lines) {
      final entry = _parseLine(line);
      if (entry == null) {
        continue;
      }
      final tag = entry.tag;
      final message = entry.message;

      if (tag == 'PlaybackHealthMonitor' &&
          message.contains('firstFrameRendered ttffMs=')) {
        firstFrameRenderedCount += 1;
        firstFrameTtffMs ??= _firstInt(message);
        _addObservation(
          observationBuckets,
          code: 'first_frame_rendered',
          tag: tag,
          message: message,
          sampleLine: line,
        );
        continue;
      }

      if (tag == 'PlaybackHealthMonitor' && message.contains('playerReady')) {
        playerReadyCount += 1;
        _addObservation(
          observationBuckets,
          code: 'player_ready',
          tag: tag,
          message: 'playerReady',
          sampleLine: line,
        );
        continue;
      }

      if (tag == 'PlaybackHealthMonitor' &&
          message.contains('playbackStarted')) {
        playbackStartedCount += 1;
        _addObservation(
          observationBuckets,
          code: 'playback_started',
          tag: tag,
          message: 'playbackStarted',
          sampleLine: line,
        );
        continue;
      }

      if (tag == 'PlaybackHealthMonitor' && message.startsWith('position=')) {
        _addObservation(
          playbackPositionBuckets,
          code: 'playback_position',
          tag: tag,
          message: message,
          sampleLine: line,
        );
        continue;
      }

      if (tag == 'ExoPlayerPlaybackProbe' &&
          message.contains('firstFrameRendered')) {
        _addObservation(
          observationBuckets,
          code: 'exo_first_frame_rendered',
          tag: tag,
          message: message,
          sampleLine: line,
        );
        continue;
      }

      if (tag == 'FrameEvents' && message.contains('Did not find frame')) {
        frameAcquireFenceMissCount += 1;
        _addIssue(
          issueBuckets,
          code: 'frame_events_missing_acquire_fence',
          severity: 'warning',
          tag: tag,
          message: 'Frame acquire fence was missing during rendering.',
          sampleLine: line,
        );
        continue;
      }

      if (tag == 'mali_winsys' &&
          message.contains('Unrecognised Android chroma siting range')) {
        chromaSitingWarningCount += 1;
        _addIssue(
          issueBuckets,
          code: 'gpu_chroma_siting_unrecognised',
          severity: 'warning',
          tag: tag,
          message: 'GPU reported an unrecognised Android chroma siting range.',
          sampleLine: line,
        );
        continue;
      }

      if (tag == 'PesReader' &&
          message.contains('Unexpected start code prefix')) {
        pesStartCodeWarningCount += 1;
        _addIssue(
          issueBuckets,
          code: 'unexpected_pes_start_code',
          severity: 'warning',
          tag: tag,
          message: 'Unexpected PES start code prefix observed during playback.',
          sampleLine: line,
        );
        continue;
      }

      if (tag == 'JavaBinder' &&
          message.contains('did not call unlinkToDeath')) {
        _addIssue(
          issueBuckets,
          code: 'binder_death_recipient_leak',
          severity: 'warning',
          tag: tag,
          message: 'Binder death recipient was leaked before teardown.',
          sampleLine: line,
        );
        continue;
      }

      if (message.contains('avc:  denied') ||
          message.contains('permission denied')) {
        _addIssue(
          issueBuckets,
          code: 'permission_denied',
          severity: 'error',
          tag: tag,
          message: 'Permission denial surfaced in device logs.',
          sampleLine: line,
        );
        continue;
      }

      if (message.contains('FATAL EXCEPTION') ||
          message.contains('fatal signal') ||
          message.contains(' ANR ') ||
          message.contains('has died')) {
        _addIssue(
          issueBuckets,
          code: 'fatal_runtime_signal',
          severity: 'blocking',
          tag: tag,
          message: 'Fatal runtime signal observed in device logs.',
          sampleLine: line,
        );
      }
    }

    if (firstFrameRenderedCount == 0 &&
        playerReadyCount == 0 &&
        playbackStartedCount == 0) {
      for (final entry in playbackPositionBuckets.values) {
        if (entry.count < _stagnantPlaybackPositionThreshold) {
          continue;
        }
        _addIssue(
          issueBuckets,
          code: 'playback_position_stuck',
          severity: 'warning',
          tag: entry.tag,
          message:
              'Playback position repeated without ready/start/first-frame signals: ${entry.message}',
          sampleLine: entry.sampleLine,
          increment: entry.count,
        );
      }
    }

    final issues = issueBuckets.values
        .map((entry) => entry.toIssue())
        .toList(growable: false)
      ..sort(_compareIssues);
    final observations = observationBuckets.values
        .map((entry) => entry.toObservation())
        .toList(growable: false)
      ..sort((a, b) => b.count.compareTo(a.count));

    final blockingCount =
        issues.where((issue) => issue.severity == 'blocking').length;
    final errorCount =
        issues.where((issue) => issue.severity == 'error').length;
    final warningCount =
        issues.where((issue) => issue.severity == 'warning').length;
    final hasBlocking = blockingCount > 0;
    final hasIssues = issues.isNotEmpty;

    return DeviceLogReport(
      source: <String, dynamic>{
        'type': 'device_logcat',
        'platform': platform,
        'deviceId': deviceId,
        'packageName': packageName,
        'processId': processId,
        'lineCount': lines.length,
      },
      summary: <String, dynamic>{
        'headline': hasBlocking
            ? 'Device log review blocking'
            : hasIssues
                ? 'Device log review required'
                : 'Device log review clean',
        'issueCount': issues.length,
        'blockingCount': blockingCount,
        'errorCount': errorCount,
        'warningCount': warningCount,
        'hasIssues': hasIssues,
        'hasBlocking': hasBlocking,
        'adminReportRequired': lines.isNotEmpty,
        'triageState': lines.isEmpty ? 'no_device_log' : 'pending_admin_report',
      },
      metrics: <String, dynamic>{
        'firstFrameTtffMs': firstFrameTtffMs,
        'firstFrameRenderedCount': firstFrameRenderedCount,
        'playerReadyCount': playerReadyCount,
        'playbackStartedCount': playbackStartedCount,
        'frameAcquireFenceMissCount': frameAcquireFenceMissCount,
        'chromaSitingWarningCount': chromaSitingWarningCount,
        'pesStartCodeWarningCount': pesStartCodeWarningCount,
      },
      issues: issues,
      observations: observations.take(6).toList(growable: false),
    );
  }

  static int _compareIssues(DeviceLogIssue a, DeviceLogIssue b) {
    final severityCompare =
        _severityRank(a.severity).compareTo(_severityRank(b.severity));
    if (severityCompare != 0) {
      return severityCompare;
    }
    return b.count.compareTo(a.count);
  }

  static int _severityRank(String severity) {
    switch (severity) {
      case 'blocking':
        return 0;
      case 'error':
        return 1;
      case 'warning':
        return 2;
      default:
        return 3;
    }
  }

  static _ParsedLogLine? _parseLine(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.startsWith('---------')) {
      return null;
    }
    final match = RegExp(
      r'^\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}\s+\d+\s+\d+\s+[A-Z]\s+([^:]+):\s+(.*)$',
    ).firstMatch(trimmed);
    if (match == null) {
      return _ParsedLogLine(tag: 'unknown', message: trimmed);
    }
    final rawTag = match.group(1)?.trim() ?? 'unknown';
    final tag = rawTag.split('#').first.trim();
    final message = match.group(2)?.trim() ?? '';
    return _ParsedLogLine(tag: tag, message: message);
  }

  static int? _firstInt(String input) {
    final match = RegExp(r'(\d+)').firstMatch(input);
    return int.tryParse(match?.group(1) ?? '');
  }

  static void _addIssue(
    Map<String, _MutableLogEntry> buckets, {
    required String code,
    required String severity,
    required String tag,
    required String message,
    required String sampleLine,
    int increment = 1,
  }) {
    final key = '$severity|$code|$tag|$message';
    final entry = buckets.putIfAbsent(
      key,
      () => _MutableLogEntry(
        code: code,
        severity: severity,
        tag: tag,
        message: message,
        sampleLine: sampleLine,
      ),
    );
    entry.count += increment;
  }

  static void _addObservation(
    Map<String, _MutableLogEntry> buckets, {
    required String code,
    required String tag,
    required String message,
    required String sampleLine,
  }) {
    final key = '$code|$tag|$message';
    final entry = buckets.putIfAbsent(
      key,
      () => _MutableLogEntry(
        code: code,
        severity: 'info',
        tag: tag,
        message: message,
        sampleLine: sampleLine,
      ),
    );
    entry.count += 1;
  }
}

class _MutableLogEntry {
  _MutableLogEntry({
    required this.code,
    required this.severity,
    required this.tag,
    required this.message,
    required this.sampleLine,
  });

  final String code;
  final String severity;
  final String tag;
  final String message;
  final String sampleLine;
  int count = 0;

  DeviceLogIssue toIssue() {
    return DeviceLogIssue(
      code: code,
      severity: severity,
      tag: tag,
      message: message,
      count: count,
      sampleLine: sampleLine,
    );
  }

  DeviceLogObservation toObservation() {
    return DeviceLogObservation(
      code: code,
      tag: tag,
      message: message,
      count: count,
    );
  }
}

class _ParsedLogLine {
  const _ParsedLogLine({
    required this.tag,
    required this.message,
  });

  final String tag;
  final String message;
}
