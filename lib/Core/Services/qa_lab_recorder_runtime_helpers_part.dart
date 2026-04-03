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

  bool _matchesPlaybackDocForSurface({
    required String surface,
    required String expectedDocId,
    required String currentDocId,
  }) {
    final expected = expectedDocId.trim();
    final current = currentDocId.trim();
    if (expected.isEmpty || current.isEmpty) return false;
    if (current == expected) return true;
    if (surface == 'feed') {
      return current == 'feed:$expected';
    }
    if (surface == 'short') {
      return current == 'short:$expected';
    }
    return false;
  }

  bool _nativePlaybackAwaitingBackgroundRecovery(
      Map<String, dynamic> snapshot) {
    final nestedSnapshot = snapshot['snapshot'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final awaitingBackgroundRecovery = _runtimeSignalAsBool(
          snapshot['awaitingBackgroundRecovery'],
          fallback: false,
        ) ||
        _runtimeSignalAsBool(
          nestedSnapshot['awaitingBackgroundRecovery'],
          fallback: false,
        );
    if (!awaitingBackgroundRecovery) {
      return false;
    }
    final appBackgroundedAt = _asInt(
      nestedSnapshot['appBackgroundedAt'] ??
          nestedSnapshot['appDidEnterBackgroundAt'],
    );
    final appForegroundedAt = _asInt(
      nestedSnapshot['appForegroundedAt'] ??
          nestedSnapshot['appWillEnterForegroundAt'],
    );
    return appBackgroundedAt > 0 &&
        (appForegroundedAt <= 0 || appForegroundedAt < appBackgroundedAt);
  }

  bool _hasRecentUnresolvedLifecycleInterruption({
    required List<QALabIssue> surfaceIssues,
    required DateTime referenceTime,
    Duration window = const Duration(seconds: 12),
  }) {
    DateTime? latestInterruptionAt;
    DateTime? latestResumeAt;

    for (final issue in surfaceIssues) {
      if (issue.source != QALabIssueSource.lifecycle) {
        continue;
      }
      if (issue.timestamp.isAfter(referenceTime)) {
        continue;
      }
      if (referenceTime.difference(issue.timestamp) > window) {
        continue;
      }
      if (issue.code == 'lifecycle_resume') {
        if (latestResumeAt == null || issue.timestamp.isAfter(latestResumeAt)) {
          latestResumeAt = issue.timestamp;
        }
        continue;
      }
      if (latestInterruptionAt == null ||
          issue.timestamp.isAfter(latestInterruptionAt)) {
        latestInterruptionAt = issue.timestamp;
      }
    }

    if (latestInterruptionAt == null) {
      return false;
    }
    return latestResumeAt == null ||
        latestResumeAt.isBefore(latestInterruptionAt);
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
}
