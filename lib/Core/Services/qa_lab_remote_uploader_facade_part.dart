part of 'qa_lab_remote_uploader.dart';

QALabRemoteUploader ensureQALabRemoteUploader() {
  final existing = maybeFindQALabRemoteUploader();
  if (existing != null) return existing;
  return Get.put(QALabRemoteUploader(), permanent: true);
}

QALabRemoteUploader? maybeFindQALabRemoteUploader() {
  if (!Get.isRegistered<QALabRemoteUploader>()) {
    return null;
  }
  return Get.find<QALabRemoteUploader>();
}

extension QALabRemoteUploaderFacadePart on QALabRemoteUploader {
  Future<void> scheduleUpload({
    required Map<String, dynamic> sessionDocument,
    List<Map<String, dynamic>> occurrences = const <Map<String, dynamic>>[],
    required String reason,
    bool immediate = false,
  }) =>
      QALabRemoteUploaderRuntimePart(this).scheduleUpload(
        sessionDocument: sessionDocument,
        occurrences: occurrences,
        reason: reason,
        immediate: immediate,
      );

  Future<void> flushNow() => QALabRemoteUploaderRuntimePart(this).flushNow();

  void resetLocalState() =>
      QALabRemoteUploaderRuntimePart(this).resetLocalState();

  Future<void> _flushPending() => _qaLabRemoteUploaderFlushPending(this);

  Map<String, dynamic> _buildIssueAggregateMutation({
    required Map<String, dynamic> sessionDocument,
    required Map<String, dynamic> occurrence,
  }) =>
      _qaLabRemoteUploaderBuildIssueAggregateMutation(
        this,
        sessionDocument: sessionDocument,
        occurrence: occurrence,
      );

  Future<bool> _isRemoteGateEnabled() =>
      _qaLabRemoteUploaderIsRemoteGateEnabled(this);

  void _ensureAdminConfigSubscription() =>
      _qaLabRemoteUploaderEnsureAdminConfigSubscription(this);

  void _applyRemoteGateState({
    required bool qaEnabled,
    required String source,
  }) =>
      _qaLabRemoteUploaderApplyRemoteGateState(
        this,
        qaEnabled: qaEnabled,
        source: source,
      );

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> input) =>
      _qaLabRemoteUploaderSanitizeMap(input);

  String _safeFieldKey(String input) => _qaLabRemoteUploaderSafeFieldKey(input);

  int _asInt(Object? value) => _qaLabRemoteUploaderAsInt(value);

  void _clearPermissionDeniedBlockForNewSession(String sessionId) =>
      _qaLabRemoteUploaderClearPermissionDeniedBlockForNewSession(
        this,
        sessionId,
      );
}
