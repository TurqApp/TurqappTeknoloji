part of 'qa_lab_recorder.dart';

extension QALabRecorderRuntimeActiveIssuePart on QALabRecorder {
  List<QALabPinpointFinding> _buildActiveIssueFindings() {
    final now = DateTime.now();
    return issues
        .where((issue) => issue.severity != QALabIssueSeverity.info)
        .where((issue) => !_isSpecializedIssueCode(issue.code))
        .where((issue) => !_isResolvedPermissionIssue(issue))
        .where(
          (issue) =>
              now.difference(issue.timestamp) <=
              _activeIssueLookback(issue.severity),
        )
        .map(
          (issue) => QALabPinpointFinding(
            severity: issue.severity,
            code: issue.code,
            message: issue.message,
            route: issue.route,
            surface: issue.surface,
            timestamp: issue.timestamp,
            context: <String, dynamic>{
              'source': issue.source.name,
              'lastCheckpoint': _lastCheckpointLabelBefore(issue.timestamp),
            },
          ),
        )
        .toList(growable: false);
  }

  bool _isSpecializedIssueCode(String code) {
    return code.startsWith('video_') ||
        code.startsWith('frame_jank_') ||
        code.startsWith('cache_first_') ||
        code.startsWith('lifecycle_');
  }

  bool _isResolvedPermissionIssue(QALabIssue issue) {
    if (!issue.code.startsWith('permission_') ||
        !issue.code.endsWith('_blocked')) {
      return false;
    }
    final rawKey = issue.code.substring(
      'permission_'.length,
      issue.code.length - '_blocked'.length,
    );
    final status = lastPermissionStatuses[rawKey];
    return status == 'granted' || status == 'limited';
  }

  Duration _activeIssueLookback(QALabIssueSeverity severity) {
    switch (severity) {
      case QALabIssueSeverity.blocking:
        return const Duration(seconds: 75);
      case QALabIssueSeverity.error:
        return const Duration(seconds: 60);
      case QALabIssueSeverity.warning:
        return Duration(seconds: QALabMode.activeIssueLookbackSeconds);
      case QALabIssueSeverity.info:
        return Duration.zero;
    }
  }
}
