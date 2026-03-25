part of 'qa_lab_recorder.dart';

extension QALabRecorderRuntimeSignalsPart on QALabRecorder {
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
