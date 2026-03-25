import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';

import 'qa_lab_mode.dart';
part 'qa_lab_remote_uploader_upload_part.dart';
part 'qa_lab_remote_uploader_gate_part.dart';

class QALabRemoteUploader extends GetxService {
  QALabRemoteUploader({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestoreOverride = firestore,
        _authOverride = auth;

  static QALabRemoteUploader ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(QALabRemoteUploader(), permanent: true);
  }

  static QALabRemoteUploader? maybeFind() {
    if (!Get.isRegistered<QALabRemoteUploader>()) {
      return null;
    }
    return Get.find<QALabRemoteUploader>();
  }

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;

  final RxString lastSyncState = 'idle'.obs;
  final RxString lastSyncError = ''.obs;
  final RxString lastSyncReason = ''.obs;
  final Rxn<DateTime> lastSyncedAt = Rxn<DateTime>();
  final Rxn<DateTime> lastGateCheckedAt = Rxn<DateTime>();
  final RxBool remoteCollectionEnabled = false.obs;
  final RxInt uploadCount = 0.obs;
  final RxInt uploadedOccurrenceCount = 0.obs;

  Timer? _debounceTimer;
  StreamSubscription<Map<String, dynamic>>? _qaConfigSubscription;
  bool _syncInFlight = false;
  Map<String, dynamic>? _pendingSessionDocument;
  String _pendingReason = '';
  final Map<String, Map<String, dynamic>> _pendingOccurrences =
      <String, Map<String, dynamic>>{};
  final Set<String> _uploadedOccurrenceIds = <String>{};
  String _activeSessionId = '';
  DateTime? _lastGateRefreshAt;
  DateTime? _permissionDeniedUntil;
  String _permissionDeniedSessionId = '';

  Future<void> scheduleUpload({
    required Map<String, dynamic> sessionDocument,
    List<Map<String, dynamic>> occurrences = const <Map<String, dynamic>>[],
    required String reason,
    bool immediate = false,
  }) async {
    if (!QALabMode.remoteUploadEnabled) {
      return;
    }
    final sessionId = (sessionDocument['sessionId'] ?? '').toString().trim();
    if (sessionId.isNotEmpty && sessionId != _activeSessionId) {
      _clearPermissionDeniedBlockForNewSession(sessionId);
      _activeSessionId = sessionId;
      _uploadedOccurrenceIds.clear();
    }
    _pendingSessionDocument = _sanitizeMap(sessionDocument);
    _pendingReason = reason;
    for (final occurrence in occurrences) {
      final occurrenceId = (occurrence['occurrenceId'] ?? '').toString().trim();
      if (occurrenceId.isEmpty) {
        continue;
      }
      _pendingOccurrences[occurrenceId] = _sanitizeMap(occurrence);
    }

    _debounceTimer?.cancel();
    if (immediate) {
      await _flushPending();
      return;
    }
    _debounceTimer = Timer(
      Duration(milliseconds: QALabMode.remoteUploadDebounceMs),
      () => unawaited(_flushPending()),
    );
  }

  Future<void> flushNow() async {
    _debounceTimer?.cancel();
    await _flushPending();
  }

  void resetLocalState() {
    _debounceTimer?.cancel();
    _pendingSessionDocument = null;
    _pendingReason = '';
    _pendingOccurrences.clear();
    _uploadedOccurrenceIds.clear();
    _activeSessionId = '';
    _permissionDeniedSessionId = '';
    _permissionDeniedUntil = null;
    uploadCount.value = 0;
    uploadedOccurrenceCount.value = 0;
    lastSyncState.value = 'idle';
    lastSyncError.value = '';
    lastSyncReason.value = '';
    lastSyncedAt.value = null;
  }

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

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _qaConfigSubscription?.cancel();
    super.onClose();
  }
}
