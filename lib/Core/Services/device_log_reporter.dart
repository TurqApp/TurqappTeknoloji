import 'dart:convert';

dynamic _cloneDeviceLogValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key.toString(),
        _cloneDeviceLogValue(nestedValue),
      ),
    );
  }
  if (value is List) {
    return value.map(_cloneDeviceLogValue).toList(growable: false);
  }
  return value;
}

Map<String, dynamic> _cloneDeviceLogMap(Map source) {
  return source.map(
    (key, value) => MapEntry(key.toString(), _cloneDeviceLogValue(value)),
  );
}

class DeviceLogIssue {
  DeviceLogIssue({
    required this.code,
    required this.severity,
    required this.tag,
    required this.message,
    required this.count,
    required this.sampleLine,
    Map<String, dynamic>? context,
  }) : context = context == null ? null : _cloneDeviceLogMap(context);

  final String code;
  final String severity;
  final String tag;
  final String message;
  final int count;
  final String sampleLine;
  final Map<String, dynamic>? context;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'code': code,
      'severity': severity,
      'tag': tag,
      'message': message,
      'count': count,
      'sampleLine': sampleLine,
      'type': 'device_log',
    };
    if (context != null && context!.isNotEmpty) {
      json['context'] = _cloneDeviceLogMap(context!);
    }
    return json;
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
  DeviceLogReport({
    required Map<String, dynamic> source,
    required Map<String, dynamic> summary,
    required Map<String, dynamic> metrics,
    required List<DeviceLogIssue> issues,
    required List<DeviceLogObservation> observations,
  })  : source = _cloneDeviceLogMap(source),
        summary = _cloneDeviceLogMap(summary),
        metrics = _cloneDeviceLogMap(metrics),
        issues = List<DeviceLogIssue>.from(issues, growable: false),
        observations = List<DeviceLogObservation>.from(
          observations,
          growable: false,
        );

  final Map<String, dynamic> source;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> metrics;
  final List<DeviceLogIssue> issues;
  final List<DeviceLogObservation> observations;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'source': _cloneDeviceLogMap(source),
      'summary': _cloneDeviceLogMap(summary),
      'metrics': _cloneDeviceLogMap(metrics),
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
  static const int _frameBurstGapMs = 250;
  static const int _frameContextWindowMs = 1500;
  static const int _pesSegmentContextWindowMs = 2500;
  static const String _frameAcquireFenceMessage =
      'Frame acquire fence was missing during rendering.';
  static const String _appCheckPlaceholderMessage =
      'App Check fell back to a placeholder or missing provider token.';
  static const String _googleApiDeveloperErrorMessage =
      'Google Play services reported a developer configuration error.';
  static const String _hlsProxyFallbackMessage =
      'HLS adapter kept the original CDN URL because proxy/cache warmup was not ready.';
  static const String _surfaceFreeAllBuffersMessage =
      'Surface pipeline freed queued buffers during playback.';

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
    final parsedEntries = lines
        .asMap()
        .entries
        .map((entry) => _parseLine(entry.value, lineNumber: entry.key + 1))
        .whereType<_ParsedLogLine>()
        .toList(growable: false);

    final issueBuckets = <String, _MutableLogEntry>{};
    final observationBuckets = <String, _MutableLogEntry>{};
    final playbackPositionBuckets = <String, _MutableLogEntry>{};
    final endedPlaybackSources = <String>{};
    int? firstFrameTtffMs;
    var firstFrameRenderedCount = 0;
    var playerReadyCount = 0;
    var playbackStartedCount = 0;
    var frameAcquireFenceMissCount = 0;
    var chromaSitingWarningCount = 0;
    var pesStartCodeWarningCount = 0;
    var appCheckPlaceholderCount = 0;
    var googleApiDeveloperErrorCount = 0;
    var hlsProxyFallbackCount = 0;
    var surfaceFreeAllBuffersCount = 0;
    _MutableLogEntry? frameAcquireFenceIssue;

    for (final entry in parsedEntries) {
      final line = entry.rawLine;
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

      if (tag == 'ExoPlayerPlaybackProbe' &&
          message.startsWith('state=ENDED')) {
        endedPlaybackSources.add(entry.sourceKey);
        continue;
      }

      if (tag == 'PlaybackHealthMonitor' && message.startsWith('position=')) {
        if (endedPlaybackSources.contains(entry.sourceKey)) {
          continue;
        }
        _addObservation(
          playbackPositionBuckets,
          code: 'playback_position',
          tag: tag,
          message: message,
          sampleLine: line,
          bucketKey: '${entry.sourceKey}|$message',
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
        frameAcquireFenceIssue = _addIssue(
          issueBuckets,
          code: 'frame_events_missing_acquire_fence',
          severity: 'warning',
          tag: tag,
          message: _frameAcquireFenceMessage,
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
        final issue = _addIssue(
          issueBuckets,
          code: 'unexpected_pes_start_code',
          severity: 'warning',
          tag: tag,
          message: 'Unexpected PES start code prefix observed during playback.',
          sampleLine: line,
        );
        issue.context ??= _buildPesStartCodeCorrelation(parsedEntries, entry);
        continue;
      }

      if ((tag == 'LocalRequestInterceptor' ||
              tag == 'FirebaseContextProvider') &&
          message.contains('App Check token') &&
          (message.contains('placeholder token') ||
              message.contains('No AppCheckProvider installed'))) {
        appCheckPlaceholderCount += 1;
        _addIssue(
          issueBuckets,
          code: 'app_check_placeholder_token',
          severity: 'warning',
          tag: tag,
          message: _appCheckPlaceholderMessage,
          sampleLine: line,
        );
        continue;
      }

      if ((tag == 'GoogleApiManager' || tag == 'FlagRegistrar') &&
          (message.contains('DEVELOPER_ERROR') ||
              message.contains('Phenotype.API is not available'))) {
        googleApiDeveloperErrorCount += 1;
        _addIssue(
          issueBuckets,
          code: 'google_api_manager_developer_error',
          severity: 'warning',
          tag: tag,
          message: _googleApiDeveloperErrorMessage,
          sampleLine: line,
        );
        continue;
      }

      if (message.contains('Proxy fallback kept original url=')) {
        hlsProxyFallbackCount += 1;
        final issue = _addIssue(
          issueBuckets,
          code: 'hls_proxy_fallback_original_url',
          severity: 'warning',
          tag: tag,
          message: _hlsProxyFallbackMessage,
          sampleLine: line,
        );
        issue.context ??= _buildProxyFallbackContext(message);
        continue;
      }

      if (message.contains('freeAllBuffers') &&
          message.contains('buffers were freed while being dequeued')) {
        surfaceFreeAllBuffersCount += 1;
        _addIssue(
          issueBuckets,
          code: 'surface_free_all_buffers',
          severity: 'warning',
          tag: tag,
          message: _surfaceFreeAllBuffersMessage,
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
          _isRelevantProcessDeath(
            message,
            packageName: packageName,
            processId: processId,
          )) {
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

    if (frameAcquireFenceIssue != null) {
      final correlation = _buildFrameEventsCorrelation(parsedEntries);
      if (correlation != null) {
        frameAcquireFenceIssue.context = correlation.toJson();
        if (correlation.rootCauseCategory != 'unknown') {
          frameAcquireFenceIssue.message =
              '$_frameAcquireFenceMessage ${correlation.messageSuffix}';
        }
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
        'appCheckPlaceholderCount': appCheckPlaceholderCount,
        'googleApiDeveloperErrorCount': googleApiDeveloperErrorCount,
        'hlsProxyFallbackCount': hlsProxyFallbackCount,
        'surfaceFreeAllBuffersCount': surfaceFreeAllBuffersCount,
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

  static bool _isRelevantProcessDeath(
    String message, {
    required String packageName,
    required String processId,
  }) {
    if (!message.contains('has died')) {
      return false;
    }
    if (packageName.isNotEmpty && message.contains(packageName)) {
      return true;
    }
    if (processId.isEmpty) {
      return false;
    }
    return message.contains('($processId)') ||
        message.contains(' $processId ') ||
        message.contains('pid $processId') ||
        message.contains('pid=$processId');
  }

  static _ParsedLogLine? _parseLine(String raw, {required int lineNumber}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.startsWith('---------')) {
      return null;
    }
    final match = RegExp(
      r'^(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\s+\d+\s+\d+\s+[A-Z]\s+([^:]+):\s+(.*)$',
    ).firstMatch(trimmed);
    if (match == null) {
      return _ParsedLogLine(
        tag: 'unknown',
        sourceKey: 'unknown',
        rawLine: trimmed,
        lineNumber: lineNumber,
        timestampMs: null,
        message: trimmed,
      );
    }
    final timestampRaw = match.group(1)?.trim() ?? '';
    final rawTag = match.group(2)?.trim() ?? 'unknown';
    final tagParts = rawTag.split('#');
    final tag = tagParts.first.trim();
    final sourceKey = tagParts.length > 1 ? tagParts.last.trim() : rawTag;
    final message = match.group(3)?.trim() ?? '';
    return _ParsedLogLine(
      tag: tag,
      sourceKey: sourceKey,
      rawLine: trimmed,
      lineNumber: lineNumber,
      timestampMs: _parseTimestampMs(timestampRaw),
      message: message,
    );
  }

  static int? _firstInt(String input) {
    final match = RegExp(r'(\d+)').firstMatch(input);
    return int.tryParse(match?.group(1) ?? '');
  }

  static Map<String, dynamic>? _buildProxyFallbackContext(String message) {
    final urlMatch = RegExp(r'url=([^\s]+)').firstMatch(message);
    final proxyRegisteredMatch =
        RegExp(r'proxyRegistered=(true|false)').firstMatch(message);
    final proxyStartedMatch =
        RegExp(r'proxyStarted=(true|false)').firstMatch(message);
    final cacheReadyMatch =
        RegExp(r'cacheReady=(true|false)').firstMatch(message);

    final context = <String, dynamic>{};
    final url = urlMatch?.group(1)?.trim() ?? '';
    if (url.isNotEmpty) {
      context['url'] = url;
    }
    if (proxyRegisteredMatch != null) {
      context['proxyRegistered'] = proxyRegisteredMatch.group(1) == 'true';
    }
    if (proxyStartedMatch != null) {
      context['proxyStarted'] = proxyStartedMatch.group(1) == 'true';
    }
    if (cacheReadyMatch != null) {
      context['cacheReady'] = cacheReadyMatch.group(1) == 'true';
    }
    return context.isEmpty ? null : context;
  }

  static int? _parseTimestampMs(String input) {
    final match = RegExp(r'^\d{2}-\d{2} (\d{2}):(\d{2}):(\d{2})\.(\d{3})$')
        .firstMatch(input);
    if (match == null) {
      return null;
    }
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    final second = int.tryParse(match.group(3) ?? '');
    final millisecond = int.tryParse(match.group(4) ?? '');
    if (hour == null ||
        minute == null ||
        second == null ||
        millisecond == null) {
      return null;
    }
    return (((hour * 60) + minute) * 60 + second) * 1000 + millisecond;
  }

  static _FrameEventsCorrelation? _buildFrameEventsCorrelation(
    List<_ParsedLogLine> entries,
  ) {
    final frameEntries = entries
        .where(
          (entry) =>
              entry.tag == 'FrameEvents' &&
              entry.timestampMs != null &&
              entry.message.contains('Did not find frame'),
        )
        .toList(growable: false);
    if (frameEntries.isEmpty) {
      return null;
    }

    final bursts = <List<_ParsedLogLine>>[];
    var currentBurst = <_ParsedLogLine>[frameEntries.first];
    for (final entry in frameEntries.skip(1)) {
      final previous = currentBurst.last;
      final gapMs = entry.timestampMs! - previous.timestampMs!;
      if (gapMs <= _frameBurstGapMs) {
        currentBurst.add(entry);
        continue;
      }
      bursts.add(currentBurst);
      currentBurst = <_ParsedLogLine>[entry];
    }
    bursts.add(currentBurst);
    bursts.sort((a, b) {
      final countCompare = b.length.compareTo(a.length);
      if (countCompare != 0) {
        return countCompare;
      }
      return (b.last.timestampMs ?? 0).compareTo(a.last.timestampMs ?? 0);
    });
    final burst = bursts.first;
    final startMs = burst.first.timestampMs!;
    final endMs = burst.last.timestampMs!;
    final contextEntries = entries
        .where(
          (entry) =>
              entry.timestampMs != null &&
              entry.timestampMs! >= startMs - _frameContextWindowMs &&
              entry.timestampMs! <= endMs + _frameContextWindowMs &&
              !(entry.tag == 'FrameEvents' &&
                  entry.message.contains('Did not find frame')),
        )
        .toList(growable: false);

    final rendererRecovery = _lastMatchingEntry(
      contextEntries,
      (entry) =>
          entry.tag == 'ExoPlayerView' &&
          (entry.message.startsWith('rendererStall') ||
              entry.message.startsWith('surfaceRebind')),
    );
    final surfaceLifecycle = _lastMatchingEntry(
      contextEntries,
      (entry) =>
          entry.tag == 'PlaybackHealthMonitor' &&
          (entry.message == 'surfaceAttached' ||
              entry.message == 'surfaceDetached' ||
              entry.message == 'fullscreenTransitionStarted' ||
              entry.message == 'fullscreenTransitionEnded' ||
              entry.message == 'appBackgrounded' ||
              entry.message == 'appForegrounded'),
    );
    final bufferingTransition = _lastMatchingEntry(
      contextEntries,
      (entry) =>
          (entry.tag == 'ExoPlayerPlaybackProbe' &&
              entry.message.startsWith('state=BUFFERING')) ||
          (entry.tag == 'PlaybackHealthMonitor' &&
              (entry.message == 'bufferingStarted' ||
                  entry.message == 'bufferingEnded')),
    );
    final playbackTeardown = _lastMatchingEntry(
      contextEntries,
      (entry) =>
          (entry.tag == 'ExoPlayerPlaybackProbe' &&
              (entry.message.startsWith('state=ENDED') ||
                  entry.message.startsWith('state=IDLE'))) ||
          (entry.tag == 'PlaybackHealthMonitor' &&
              entry.message == 'playbackPaused'),
    );
    final startupTransition = _lastMatchingEntry(
      contextEntries,
      (entry) =>
          (entry.tag == 'PlaybackHealthMonitor' &&
              (entry.message == 'playerReady' ||
                  entry.message == 'playbackStarted' ||
                  entry.message.startsWith('firstFrameRendered'))) ||
          (entry.tag == 'ExoPlayerPlaybackProbe' &&
              (entry.message.startsWith('state=READY') ||
                  entry.message.startsWith('firstFrameRendered'))),
    );

    String category = 'unknown';
    _ParsedLogLine? detailEntry;
    if (rendererRecovery != null) {
      category = 'renderer_recovery';
      detailEntry = rendererRecovery;
    } else if (surfaceLifecycle != null) {
      category = 'surface_lifecycle';
      detailEntry = surfaceLifecycle;
    } else if (bufferingTransition != null) {
      category = 'buffering_transition';
      detailEntry = bufferingTransition;
    } else if (playbackTeardown != null) {
      category = 'playback_teardown';
      detailEntry = playbackTeardown;
    } else if (startupTransition != null) {
      category = 'startup_render_transition';
      detailEntry = startupTransition;
    }

    final signalEntries = <_ParsedLogLine>[
      if (detailEntry != null) detailEntry,
      ...contextEntries.where(
        (entry) =>
            entry.tag == 'ExoPlayerPlaybackProbe' ||
            entry.tag == 'PlaybackHealthMonitor' ||
            entry.tag == 'ExoPlayerView',
      ),
    ];
    final contextSignals = <String>[];
    final seenSignals = <String>{};
    for (final entry in signalEntries.reversed) {
      final signal = _signalLabel(entry);
      if (signal.isEmpty || !seenSignals.add(signal)) {
        continue;
      }
      contextSignals.add(signal);
      if (contextSignals.length >= 6) {
        break;
      }
    }

    final playbackSources = contextEntries
        .where((entry) =>
            entry.sourceKey != 'unknown' && entry.sourceKey != entry.tag)
        .map((entry) => entry.sourceKey)
        .toSet()
        .toList(growable: false)
      ..sort();

    return _FrameEventsCorrelation(
      burstCount: burst.length,
      startLine: burst.first.lineNumber,
      endLine: burst.last.lineNumber,
      playbackSources: playbackSources,
      rootCauseCategory: category,
      rootCauseDetail: detailEntry?.message ?? '',
      contextSignals: contextSignals,
    );
  }

  static Map<String, dynamic>? _buildPesStartCodeCorrelation(
    List<_ParsedLogLine> entries,
    _ParsedLogLine warningEntry,
  ) {
    final warningTs = warningEntry.timestampMs;
    if (warningTs == null) {
      return null;
    }
    _ParsedLogLine? nearest;
    for (var index = entries.length - 1; index >= 0; index -= 1) {
      final entry = entries[index];
      if (entry.timestampMs == null || entry.timestampMs! > warningTs) {
        continue;
      }
      if (!entry.message.startsWith('[HlsSegmentServe]')) {
        continue;
      }
      if (warningTs - entry.timestampMs! > _pesSegmentContextWindowMs) {
        break;
      }
      nearest = entry;
      break;
    }
    if (nearest == null) {
      return null;
    }
    final segmentContext = _parseServedSegmentContext(nearest.message);
    if (segmentContext == null || segmentContext.isEmpty) {
      return null;
    }
    return <String, dynamic>{
      'warningLine': warningEntry.lineNumber,
      'warningTimestampMs': warningTs,
      'servedSegment': segmentContext,
      'servedSegmentLine': nearest.lineNumber,
      'servedSegmentTimestampMs': nearest.timestampMs,
      'deltaMs': warningTs - (nearest.timestampMs ?? warningTs),
    };
  }

  static Map<String, dynamic>? _parseServedSegmentContext(String message) {
    final match = RegExp(
      r'^\[HlsSegmentServe\] doc=(\S+) segment=(\S+) cacheHit=(true|false) bytes=(\d+) path=(\S+)$',
    ).firstMatch(message.trim());
    if (match == null) {
      return null;
    }
    return <String, dynamic>{
      'docId': match.group(1),
      'segmentKey': match.group(2),
      'cacheHit': match.group(3) == 'true',
      'bytes': int.tryParse(match.group(4) ?? ''),
      'path': match.group(5),
    };
  }

  static _ParsedLogLine? _lastMatchingEntry(
    List<_ParsedLogLine> entries,
    bool Function(_ParsedLogLine entry) predicate,
  ) {
    for (var index = entries.length - 1; index >= 0; index -= 1) {
      final entry = entries[index];
      if (predicate(entry)) {
        return entry;
      }
    }
    return null;
  }

  static String _signalLabel(_ParsedLogLine entry) {
    final sourceSuffix =
        entry.sourceKey == 'unknown' || entry.sourceKey == entry.tag
            ? ''
            : '#${entry.sourceKey}';
    return '${entry.tag}$sourceSuffix ${entry.message}';
  }

  static _MutableLogEntry _addIssue(
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
    return entry;
  }

  static void _addObservation(
    Map<String, _MutableLogEntry> buckets, {
    required String code,
    required String tag,
    required String message,
    required String sampleLine,
    String? bucketKey,
  }) {
    final key = bucketKey ?? '$code|$tag|$message';
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
  String message;
  final String sampleLine;
  Map<String, dynamic>? context;
  int count = 0;

  DeviceLogIssue toIssue() {
    return DeviceLogIssue(
      code: code,
      severity: severity,
      tag: tag,
      message: message,
      count: count,
      sampleLine: sampleLine,
      context: context,
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
    required this.sourceKey,
    required this.rawLine,
    required this.lineNumber,
    required this.timestampMs,
    required this.message,
  });

  final String tag;
  final String sourceKey;
  final String rawLine;
  final int lineNumber;
  final int? timestampMs;
  final String message;
}

class _FrameEventsCorrelation {
  _FrameEventsCorrelation({
    required this.burstCount,
    required this.startLine,
    required this.endLine,
    required List<String> playbackSources,
    required this.rootCauseCategory,
    required this.rootCauseDetail,
    required List<String> contextSignals,
  })  : playbackSources = List<String>.from(
          playbackSources,
          growable: false,
        ),
        contextSignals = List<String>.from(
          contextSignals,
          growable: false,
        );

  final int burstCount;
  final int startLine;
  final int endLine;
  final List<String> playbackSources;
  final String rootCauseCategory;
  final String rootCauseDetail;
  final List<String> contextSignals;

  String get messageSuffix {
    switch (rootCauseCategory) {
      case 'renderer_recovery':
        return 'Correlated with renderer recovery: $rootCauseDetail';
      case 'surface_lifecycle':
        return 'Correlated with surface lifecycle: $rootCauseDetail';
      case 'buffering_transition':
        return 'Correlated with buffering transition: $rootCauseDetail';
      case 'playback_teardown':
        return 'Correlated with playback teardown: $rootCauseDetail';
      case 'startup_render_transition':
        return 'Correlated with startup/render transition: $rootCauseDetail';
      default:
        return '';
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'burstCount': burstCount,
      'startLine': startLine,
      'endLine': endLine,
      'playbackSources': List<String>.from(playbackSources, growable: false),
      'rootCauseCategory': rootCauseCategory,
      'rootCauseDetail': rootCauseDetail,
      'contextSignals': List<String>.from(contextSignals, growable: false),
    };
  }
}
