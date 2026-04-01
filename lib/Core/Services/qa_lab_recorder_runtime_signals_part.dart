part of 'qa_lab_recorder.dart';

extension QALabRecorderRuntimeSignalsPart on QALabRecorder {
  bool _runtimeSignalAsBool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return fallback;
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
    return fallback;
  }

  Map<String, dynamic> _normalizeNativePlaybackSnapshot(
    Map<String, dynamic> snapshot, {
    required String trigger,
    required String? surfaceHint,
    required DateTime sampledAt,
  }) {
    final nestedSnapshot = snapshot['snapshot'] is Map
        ? _cloneQaLabExportMap(
            (snapshot['snapshot'] as Map).map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          )
        : _cloneQaLabExportMap(snapshot);
    final errors = _nativePlaybackErrors(snapshot);
    return <String, dynamic>{
      'platform': defaultTargetPlatform.name,
      'trigger': trigger,
      'surfaceHint': surfaceHint ?? '',
      'sampledAt': sampledAt.toUtc().toIso8601String(),
      'supported': _runtimeSignalAsBool(snapshot['supported'], fallback: true),
      'active': _runtimeSignalAsBool(snapshot['active'], fallback: false),
      'status': (snapshot['status'] ?? '').toString(),
      'errors': errors,
      'firstFrameRendered': _runtimeSignalAsBool(snapshot['firstFrameRendered'],
              fallback: false) ||
          _runtimeSignalAsBool(
            nestedSnapshot['hasRenderedFirstFrame'],
            fallback: false,
          ),
      'isPlaybackExpected': _runtimeSignalAsBool(
        nestedSnapshot['isPlaybackExpected'],
        fallback: false,
      ),
      'isPlaying': _runtimeSignalAsBool(
        nestedSnapshot['isPlaying'],
        fallback: false,
      ),
      'isBuffering': _runtimeSignalAsBool(
        nestedSnapshot['isBuffering'],
        fallback: false,
      ),
      'stallCount': _asInt(nestedSnapshot['stallCount']),
      'layerAttachCount': _asInt(nestedSnapshot['layerAttachCount']),
      'lastKnownPlaybackTime':
          _asDouble(nestedSnapshot['lastKnownPlaybackTime']),
      'awaitingFullscreenRecovery': _runtimeSignalAsBool(
        nestedSnapshot['awaitingFullscreenRecovery'],
        fallback: false,
      ),
      'awaitingBackgroundRecovery': _runtimeSignalAsBool(
        nestedSnapshot['awaitingBackgroundRecovery'],
        fallback: false,
      ),
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
