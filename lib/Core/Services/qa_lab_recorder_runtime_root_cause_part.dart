part of 'qa_lab_recorder.dart';

extension QALabRecorderRuntimeRootCausePart on QALabRecorder {
  (String, String) _inferPrimaryRootCause(
    QALabSurfaceDiagnostic diagnostic,
    List<QALabPinpointFinding> findings,
    String headlineCode,
  ) {
    final mapped = _inferMappedPrimaryRootCause(
      diagnostic: diagnostic,
      headlineCode: headlineCode,
    );
    if (mapped != null) {
      return mapped;
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
}
