part of 'qa_lab_recorder.dart';

extension QALabRecorderRuntimeHelpersPart on QALabRecorder {
  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }

  int _compareFindings(QALabPinpointFinding a, QALabPinpointFinding b) {
    final severityCompare =
        _severityRank(b.severity) - _severityRank(a.severity);
    if (severityCompare != 0) return severityCompare;
    return b.timestamp.compareTo(a.timestamp);
  }

  int _severityRank(QALabIssueSeverity severity) {
    switch (severity) {
      case QALabIssueSeverity.blocking:
        return 4;
      case QALabIssueSeverity.error:
        return 3;
      case QALabIssueSeverity.warning:
        return 2;
      case QALabIssueSeverity.info:
        return 1;
    }
  }

  int _compareSurfaceAlertSummaries(
    QALabSurfaceAlertSummary a,
    QALabSurfaceAlertSummary b,
  ) {
    final severityCompare = ((b.blockingCount * 1000) +
            (b.errorCount * 100) +
            (b.warningCount * 10) +
            (100 - b.healthScore)) -
        ((a.blockingCount * 1000) +
            (a.errorCount * 100) +
            (a.warningCount * 10) +
            (100 - a.healthScore));
    if (severityCompare != 0) {
      return severityCompare;
    }
    return a.surface.compareTo(b.surface);
  }

  (String, String) _inferPrimaryRootCause(
    QALabSurfaceDiagnostic diagnostic,
    List<QALabPinpointFinding> findings,
    String headlineCode,
  ) {
    final runtime = diagnostic.runtime;
    final code = headlineCode.trim().toLowerCase();

    if (code.contains('blank_surface')) {
      return (
        'data_absent',
        '${diagnostic.surface} loaded as an empty authenticated surface.',
      );
    }
    if (code.contains('autoplay') || code.contains('playback_gate')) {
      return (
        'autoplay_dispatch',
        '${diagnostic.surface} had eligible content but autoplay did not lock onto the expected video.',
      );
    }
    if (code.contains('duplicate_fetch')) {
      return (
        'feed_trigger_duplication',
        '${diagnostic.surface} triggered repeated feed loads before a prior fetch settled.',
      );
    }
    if (code.contains('duplicate_playback_dispatch')) {
      return (
        'playback_dispatch_duplication',
        '${diagnostic.surface} issued repeated playback commands against the same item in a tight burst.',
      );
    }
    if (code.contains('scroll_dispatch') ||
        code.contains('scroll_first_frame')) {
      return (
        'scroll_autoplay_latency',
        '${diagnostic.surface} lost time between scroll settle, playback dispatch, and the first rendered frame.',
      );
    }
    if (code.contains('first_frame')) {
      return (
        'first_frame_latency',
        '${diagnostic.surface} started playback but first frame confirmation lagged or never arrived.',
      );
    }
    if (code.contains('black_screen')) {
      return (
        'first_frame_latency',
        '${diagnostic.surface} reattached video layers before a stable first frame and risks blank flashes.',
      );
    }
    if (code.contains('buffer_stall') || code.contains('rebuffer')) {
      return (
        'buffering_instability',
        '${diagnostic.surface} playback spent too long buffering or repeatedly rebuffered.',
      );
    }
    if (code.contains('audio_state') || code.contains('mute')) {
      return (
        'audio_state_drift',
        '${diagnostic.surface} produced inconsistent audible state across video sessions.',
      );
    }
    if (code.contains('thumbnail_only')) {
      return (
        'playback_session_loss',
        '${diagnostic.surface} had prior video success in the session but later regressed to thumbnail-only playback.',
      );
    }
    if (code.contains('ad_load') || code.contains('ad_retry')) {
      return (
        'ad_loading_latency',
        '${diagnostic.surface} ad lifecycle added delay, failure, or retry pressure during rendering.',
      );
    }
    if (code.contains('cache_live_failures') ||
        (runtime['cacheFailureCount'] as int? ?? 0) > 0) {
      return (
        'cache_live_sync',
        '${diagnostic.surface} cache-first flow preserved stale state or failed to refresh live data.',
      );
    }
    if (code.contains('permission')) {
      return (
        'permission_block',
        '${diagnostic.surface} is blocked by OS-level permission state.',
      );
    }
    if (code.contains('jank') || code.contains('noise_burst')) {
      return (
        'runtime_noise',
        '${diagnostic.surface} accumulated frame jank or suppressed runtime noise.',
      );
    }
    if (code.contains('lifecycle')) {
      return (
        'lifecycle_interruption',
        '${diagnostic.surface} was interrupted by app lifecycle transitions.',
      );
    }
    if (code.contains('interrupted')) {
      return (
        'lifecycle_interruption',
        '${diagnostic.surface} failed to recover cleanly after a fullscreen or background interruption.',
      );
    }
    if (code.contains('route_resolution')) {
      return (
        'route_resolution',
        '${diagnostic.surface} opened without completing target route resolution.',
      );
    }
    if (code.contains('media_failure')) {
      return (
        'media_pipeline',
        '${diagnostic.surface} reported a media pipeline failure.',
      );
    }
    if (code == 'coverage_gap') {
      return (
        'coverage_gap',
        '${diagnostic.surface} still has missing QA coverage tags.',
      );
    }

    final blockingCount = findings
        .where((item) => item.severity == QALabIssueSeverity.blocking)
        .length;
    final errorCount = findings
        .where((item) => item.severity == QALabIssueSeverity.error)
        .length;
    if (blockingCount > 0 || errorCount > 0) {
      return (
        'runtime_regression',
        '${diagnostic.surface} has high-severity findings without a specialized root-cause mapping yet.',
      );
    }
    return (
      'observation_only',
      '${diagnostic.surface} is degraded, but only low-severity observations are present so far.',
    );
  }

  List<QALabPinpointFinding> _dedupeFindings(
    List<QALabPinpointFinding> findings,
  ) {
    final seen = <String>{};
    final deduped = <QALabPinpointFinding>[];
    for (final finding in findings) {
      final key = [
        finding.surface,
        finding.route,
        finding.code,
        finding.message,
      ].join('|');
      if (!seen.add(key)) continue;
      deduped.add(finding);
    }
    return deduped;
  }

  void _trimList<T>(RxList<T> list, int maxCount) {
    if (list.length <= maxCount) return;
    list.removeRange(0, list.length - maxCount);
  }

  void _cancelSurfaceWatchdog(String surface) {
    _surfaceWatchdogs.remove(surface)?.cancel();
  }

  void _cancelAllSurfaceWatchdogs() {
    for (final timer in _surfaceWatchdogs.values) {
      timer.cancel();
    }
    _surfaceWatchdogs.clear();
  }

  bool get _supportsNativePlaybackSampling =>
      GetPlatform.isIOS || GetPlatform.isAndroid;

  Map<String, dynamic> _normalizeNativePlaybackSnapshot(
    Map<String, dynamic> snapshot, {
    required String trigger,
    required String? surfaceHint,
    required DateTime sampledAt,
  }) {
    final nestedSnapshot = snapshot['snapshot'] is Map
        ? Map<String, dynamic>.from(snapshot['snapshot'] as Map)
        : Map<String, dynamic>.from(snapshot);
    final errors = _nativePlaybackErrors(snapshot);
    return <String, dynamic>{
      'platform': defaultTargetPlatform.name,
      'trigger': trigger,
      'surfaceHint': surfaceHint ?? '',
      'sampledAt': sampledAt.toUtc().toIso8601String(),
      'supported': snapshot['supported'] != false,
      'active': snapshot['active'] == true,
      'status': (snapshot['status'] ?? '').toString(),
      'errors': errors,
      'firstFrameRendered': snapshot['firstFrameRendered'] == true ||
          nestedSnapshot['hasRenderedFirstFrame'] == true,
      'isPlaybackExpected': nestedSnapshot['isPlaybackExpected'] == true,
      'isPlaying': nestedSnapshot['isPlaying'] == true,
      'isBuffering': nestedSnapshot['isBuffering'] == true,
      'stallCount': _asInt(nestedSnapshot['stallCount']),
      'layerAttachCount': _asInt(nestedSnapshot['layerAttachCount']),
      'lastKnownPlaybackTime':
          _asDouble(nestedSnapshot['lastKnownPlaybackTime']),
      'awaitingFullscreenRecovery':
          nestedSnapshot['awaitingFullscreenRecovery'] == true,
      'awaitingBackgroundRecovery':
          nestedSnapshot['awaitingBackgroundRecovery'] == true,
      'raw': (snapshot['raw'] ?? '').toString(),
      'snapshot': nestedSnapshot,
    };
  }

  List<String> _nativePlaybackErrors(Map<String, dynamic> snapshot) {
    final rawErrors = snapshot['errors'];
    if (rawErrors is! List) {
      return const <String>[];
    }
    return rawErrors
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  bool _nativePlaybackSampleEquivalent(
    Map<String, dynamic> previous,
    Map<String, dynamic> current,
  ) {
    final previousErrors = _nativePlaybackErrors(previous);
    final currentErrors = _nativePlaybackErrors(current);
    return previous['platform'] == current['platform'] &&
        previous['status'] == current['status'] &&
        previous['active'] == current['active'] &&
        previous['firstFrameRendered'] == current['firstFrameRendered'] &&
        previous['isPlaybackExpected'] == current['isPlaybackExpected'] &&
        previous['isPlaying'] == current['isPlaying'] &&
        previous['isBuffering'] == current['isBuffering'] &&
        _asInt(previous['stallCount']) == _asInt(current['stallCount']) &&
        _asInt(previous['layerAttachCount']) ==
            _asInt(current['layerAttachCount']) &&
        _asDouble(previous['lastKnownPlaybackTime']) ==
            _asDouble(current['lastKnownPlaybackTime']) &&
        listEquals(previousErrors, currentErrors);
  }

  void _maybeEmitAutoSignals() {
    if (!QALabMode.enabled) {
      return;
    }
    var shouldAutoExport = false;
    for (final finding in buildPinpointFindings()) {
      final key = [
        finding.surface,
        finding.route,
        finding.code,
        finding.message,
      ].join('|');
      if (!_emittedFindingKeys.add(key)) {
        continue;
      }
      if (QALabMode.autoMarkerLogs) {
        debugPrint(_formatFindingMarker(finding));
      }
      if (_severityRank(finding.severity) >=
          _severityRank(QALabIssueSeverity.error)) {
        shouldAutoExport = true;
      }
    }
    if (shouldAutoExport && QALabMode.autoExportFindings) {
      _scheduleAutoExport();
    }
    if (shouldAutoExport && QALabMode.remoteUploadEnabled) {
      unawaited(
        syncRemoteSummary(
          reason: 'auto_finding',
          immediate: true,
        ),
      );
    }
  }

  String _formatFindingMarker(QALabPinpointFinding finding) {
    return '[QA_LAB][${finding.severity.name.toUpperCase()}]'
        '[${finding.surface}] ${finding.code} route=${finding.route} '
        'message=${finding.message}';
  }

  void _scheduleAutoExport() {
    if (_autoExportInFlight) {
      return;
    }
    final now = DateTime.now();
    final previous = _lastAutoExportAt;
    if (previous != null &&
        now.difference(previous) < const Duration(seconds: 2)) {
      return;
    }
    _lastAutoExportAt = now;
    _autoExportInFlight = true;
    unawaited(
      exportSessionJson().then((file) {
        if (QALabMode.autoMarkerLogs) {
          debugPrint('[QA_LAB][EXPORT] ${file.path}');
        }
      }).catchError((Object error, StackTrace stackTrace) {
        debugPrint(
          '[QA_LAB][EXPORT_ERROR] ${error.runtimeType}: $error\n$stackTrace',
        );
      }).whenComplete(() {
        _autoExportInFlight = false;
      }),
    );
  }
}
