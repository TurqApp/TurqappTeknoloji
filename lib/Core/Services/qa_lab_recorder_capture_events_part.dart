part of 'qa_lab_recorder.dart';

extension QALabRecorderCaptureEventsPart on QALabRecorder {
  void recordFlutterError(
    FlutterErrorDetails details, {
    bool suppressed = false,
    String sourceLabel = 'flutter',
  }) {
    final message = details.exceptionAsString();
    recordIssue(
      source: QALabIssueSource.flutter,
      code: suppressed ? 'flutter_suppressed' : 'flutter_error',
      severity: _severityForError(message, suppressed: suppressed),
      message: message,
      stackTrace: details.stack?.toString(),
      metadata: <String, dynamic>{
        'library': details.library ?? '',
        'context': details.context?.toDescription() ?? '',
        'sourceLabel': sourceLabel,
        'suppressed': suppressed,
      },
    );
  }

  void recordPlatformError(
    Object error,
    StackTrace stackTrace, {
    bool suppressed = false,
    String sourceLabel = 'platform',
  }) {
    final message = error.toString();
    recordIssue(
      source: QALabIssueSource.platform,
      code: suppressed ? 'platform_suppressed' : 'platform_error',
      severity: _severityForError(message, suppressed: suppressed),
      message: message,
      stackTrace: stackTrace.toString(),
      metadata: <String, dynamic>{
        'sourceLabel': sourceLabel,
        'errorType': error.runtimeType.toString(),
        'suppressed': suppressed,
      },
    );
  }

  void recordHandledError({
    required String code,
    required String message,
    required String severity,
    required Map<String, dynamic> metadata,
    String? stackTrace,
  }) {
    recordIssue(
      source: QALabIssueSource.handled,
      code: code,
      severity: _severityFromString(severity),
      message: message,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  void recordCacheFirstEvent(Map<String, dynamic> payload) {
    final event = (payload['event'] ?? '').toString();
    final surface = _cacheSurfaceFromPayload(payload);
    if (event.contains('failed')) {
      recordIssue(
        source: QALabIssueSource.cache,
        code: 'cache_first_failed',
        severity: QALabIssueSeverity.warning,
        message: 'Cache-first live sync failed on $surface',
        metadata: payload,
      );
      return;
    }
    if (event == 'liveSyncPreservedPrevious') {
      recordIssue(
        source: QALabIssueSource.cache,
        code: 'cache_first_preserved_previous',
        severity: QALabIssueSeverity.info,
        message: 'Cache-first preserved previous snapshot on $surface',
        metadata: payload,
      );
    }
  }
}
