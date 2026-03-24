import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';

import 'qa_lab_mode.dart';

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
  StreamSubscription<Map<String, dynamic>>? _legacyAdminConfigSubscription;
  bool _syncInFlight = false;
  Map<String, dynamic>? _pendingSessionDocument;
  String _pendingReason = '';
  final Map<String, Map<String, dynamic>> _pendingOccurrences =
      <String, Map<String, dynamic>>{};
  final Set<String> _uploadedOccurrenceIds = <String>{};
  String _activeSessionId = '';
  DateTime? _lastGateRefreshAt;
  DateTime? _permissionDeniedUntil;
  bool _qaGateEnabled = false;
  bool _legacyGateEnabled = false;

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
    uploadCount.value = 0;
    uploadedOccurrenceCount.value = 0;
    lastSyncState.value = 'idle';
    lastSyncError.value = '';
    lastSyncReason.value = '';
    lastSyncedAt.value = null;
  }

  Future<void> _flushPending() async {
    if (_syncInFlight) {
      return;
    }
    final sessionDocument = _pendingSessionDocument;
    if (sessionDocument == null) {
      return;
    }
    if (Firebase.apps.isEmpty) {
      lastSyncState.value = 'awaiting_firebase';
      return;
    }
    final auth = _authOverride ?? FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      lastSyncState.value = 'awaiting_auth';
      return;
    }
    if (!await _isRemoteGateEnabled()) {
      return;
    }

    final reason = _pendingReason;
    final pendingOccurrences =
        _pendingOccurrences.values.toList(growable: false);
    _pendingSessionDocument = null;
    _pendingOccurrences.clear();

    _syncInFlight = true;
    lastSyncState.value = 'uploading';
    lastSyncError.value = '';
    lastSyncReason.value = reason;

    try {
      final sessionId =
          (sessionDocument['sessionId'] ?? '').toString().trim().isEmpty
              ? DateTime.now().millisecondsSinceEpoch.toString()
              : (sessionDocument['sessionId'] ?? '').toString().trim();
      final firestore = _firestoreOverride ?? FirebaseFirestore.instance;
      final scopeRef = firestore
          .collection(QALabMode.remoteCollectionName)
          .doc(QALabMode.remoteUploadScope);
      final sessionRef = scopeRef.collection('sessions').doc(sessionId);
      final batch = firestore.batch();
      final platform = (sessionDocument['platform'] ?? '').toString();
      final buildMode = (sessionDocument['buildMode'] ?? '').toString();
      final surface =
          ((sessionDocument['route'] as Map?)?['lastSurface'] ?? '').toString();

      batch.set(
        scopeRef,
        <String, dynamic>{
          'schemaVersion': 1,
          'scope': QALabMode.remoteUploadScope,
          'collection': QALabMode.remoteCollectionName,
          'lastSessionId': sessionId,
          'lastReason': reason,
          'lastPlatform': platform,
          'lastBuildMode': buildMode,
          'lastSurface': surface,
          'updatedAt': FieldValue.serverTimestamp(),
          'counters.totalUploads': FieldValue.increment(1),
          if (platform.isNotEmpty)
            'counters.byPlatform.${_safeFieldKey(platform)}':
                FieldValue.increment(1),
          if (buildMode.isNotEmpty)
            'counters.byBuildMode.${_safeFieldKey(buildMode)}':
                FieldValue.increment(1),
          if (surface.isNotEmpty)
            'counters.bySurface.${_safeFieldKey(surface)}':
                FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      batch.set(
        sessionRef,
        <String, dynamic>{
          ...sessionDocument,
          'sessionId': sessionId,
          'updatedAt': FieldValue.serverTimestamp(),
          'remote': <String, dynamic>{
            ...((sessionDocument['remote'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{}),
            'scope': QALabMode.remoteUploadScope,
            'lastReason': reason,
            'lastSyncedAt': DateTime.now().toUtc().toIso8601String(),
            'uploadCount': uploadCount.value + 1,
          },
          'user': <String, dynamic>{
            'uid': user.uid,
            'email': user.email ?? '',
            'isAnonymous': user.isAnonymous,
          },
        },
        SetOptions(merge: true),
      );

      var uploadedNow = 0;
      for (final occurrence in pendingOccurrences) {
        final occurrenceId =
            (occurrence['occurrenceId'] ?? '').toString().trim();
        final signature = (occurrence['signature'] ?? '').toString().trim();
        if (occurrenceId.isEmpty ||
            signature.isEmpty ||
            _uploadedOccurrenceIds.contains(occurrenceId)) {
          continue;
        }
        uploadedNow += 1;
        final issueRef = scopeRef.collection('issues').doc(signature);
        batch.set(
          issueRef,
          _buildIssueAggregateMutation(
            sessionDocument: sessionDocument,
            occurrence: occurrence,
          ),
          SetOptions(merge: true),
        );
        batch.set(
          issueRef.collection('occurrences').doc(occurrenceId),
          <String, dynamic>{
            ...occurrence,
            'syncedAt': FieldValue.serverTimestamp(),
            'user': <String, dynamic>{
              'uid': user.uid,
              'email': user.email ?? '',
              'isAnonymous': user.isAnonymous,
            },
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      _uploadedOccurrenceIds.addAll(
        pendingOccurrences
            .map((item) => (item['occurrenceId'] ?? '').toString().trim())
            .where((item) => item.isNotEmpty),
      );
      uploadCount.value += 1;
      uploadedOccurrenceCount.value += uploadedNow;
      lastSyncedAt.value = DateTime.now();
      _permissionDeniedUntil = null;
      lastSyncState.value = 'synced';
      lastSyncError.value = '';
    } catch (error, stackTrace) {
      _pendingSessionDocument ??= sessionDocument;
      for (final occurrence in pendingOccurrences) {
        final occurrenceId =
            (occurrence['occurrenceId'] ?? '').toString().trim();
        if (occurrenceId.isEmpty) {
          continue;
        }
        _pendingOccurrences.putIfAbsent(occurrenceId, () => occurrence);
      }
      if (error is FirebaseException && error.code == 'permission-denied') {
        _permissionDeniedUntil =
            DateTime.now().add(const Duration(minutes: 1));
        remoteCollectionEnabled.value = false;
        lastGateCheckedAt.value = DateTime.now();
        lastSyncState.value = 'permission_denied';
        lastSyncReason.value = 'write_denied';
        lastSyncError.value = '$error';
        debugPrint(
          '[QA_LAB][REMOTE_PERMISSION_DENIED] Upload disabled temporarily after write denial.\n$stackTrace',
        );
        return;
      }
      lastSyncState.value = 'error';
      lastSyncError.value = '$error';
      debugPrint(
        '[QA_LAB][REMOTE_SYNC_ERROR] ${error.runtimeType}: $error\n$stackTrace',
      );
    } finally {
      _syncInFlight = false;
    }
  }

  Map<String, dynamic> _buildIssueAggregateMutation({
    required Map<String, dynamic> sessionDocument,
    required Map<String, dynamic> occurrence,
  }) {
    final platform =
        (occurrence['platform'] ?? sessionDocument['platform'] ?? '')
            .toString();
    final buildMode =
        (occurrence['buildMode'] ?? sessionDocument['buildMode'] ?? '')
            .toString();
    final surface = (occurrence['surface'] ?? '').toString();
    final severity = (occurrence['severity'] ?? '').toString();
    final eventCount = _asInt(occurrence['eventCount']) <= 0
        ? 1
        : _asInt(occurrence['eventCount']);
    return <String, dynamic>{
      'signature': (occurrence['signature'] ?? '').toString(),
      'code': (occurrence['code'] ?? '').toString(),
      'severity': severity,
      'surface': surface,
      'routeHint': (occurrence['route'] ?? '').toString(),
      'summary': (occurrence['summary'] ?? '').toString(),
      'message': (occurrence['message'] ?? '').toString(),
      'rootCauseCategory': (occurrence['rootCauseCategory'] ?? '').toString(),
      'rootCauseDetail': (occurrence['rootCauseDetail'] ?? '').toString(),
      'lastSessionId': (occurrence['sessionId'] ?? '').toString(),
      'lastOccurrenceId': (occurrence['occurrenceId'] ?? '').toString(),
      'lastDeviceModel': (occurrence['deviceModel'] ?? '').toString(),
      'lastPlatform': platform,
      'lastBuildMode': buildMode,
      'lastAppVersion': (occurrence['appVersion'] ?? '').toString(),
      'lastSeenAt': (occurrence['timestamp'] ?? '').toString(),
      'lastUploadAt': FieldValue.serverTimestamp(),
      'counters.totalSessions': FieldValue.increment(1),
      'counters.totalEvents': FieldValue.increment(eventCount),
      if (severity.isNotEmpty)
        'counters.bySeverity.${_safeFieldKey(severity)}':
            FieldValue.increment(1),
      if (surface.isNotEmpty)
        'counters.bySurface.${_safeFieldKey(surface)}': FieldValue.increment(1),
      if (platform.isNotEmpty)
        'counters.byPlatform.${_safeFieldKey(platform)}':
            FieldValue.increment(1),
      if (buildMode.isNotEmpty)
        'counters.byBuildMode.${_safeFieldKey(buildMode)}':
            FieldValue.increment(1),
    };
  }

  Future<bool> _isRemoteGateEnabled() async {
    _ensureAdminConfigSubscription();
    final now = DateTime.now();
    if (_permissionDeniedUntil != null &&
        now.isBefore(_permissionDeniedUntil!)) {
      return false;
    }
    if (_lastGateRefreshAt != null &&
        now.difference(_lastGateRefreshAt!) < const Duration(seconds: 20)) {
      return remoteCollectionEnabled.value;
    }
    _lastGateRefreshAt = now;
    try {
      final qaDoc = await ConfigRepository.ensure().getAdminConfigDoc(
        'qa',
        preferCache: true,
        forceRefresh: false,
        ttl: const Duration(seconds: 20),
      );
      final adminDoc = await ConfigRepository.ensure().getAdminConfigDoc(
        'admin',
        preferCache: true,
        forceRefresh: false,
        ttl: const Duration(seconds: 20),
      );
      _applyRemoteGateState(
        qaEnabled: qaDoc?['qaEnabled'] == true,
        legacyEnabled: adminDoc?['qaCollectionEnabled'] == true,
        source: 'config_fetch',
      );
      return remoteCollectionEnabled.value;
    } catch (error, stackTrace) {
      lastGateCheckedAt.value = DateTime.now();
      lastSyncState.value = 'gate_error';
      lastSyncError.value = '$error';
      debugPrint(
        '[QA_LAB][REMOTE_GATE_ERROR] ${error.runtimeType}: $error\n$stackTrace',
      );
      return false;
    }
  }

  void _ensureAdminConfigSubscription() {
    if (Firebase.apps.isEmpty) {
      return;
    }
    _qaConfigSubscription ??= ConfigRepository.ensure()
        .watchAdminConfigDoc(
        'qa',
        ttl: const Duration(seconds: 20),
      )
        .listen(
        (doc) {
          _applyRemoteGateState(
            qaEnabled: doc['qaEnabled'] == true,
            legacyEnabled: _legacyGateEnabled,
            source: 'qa_watch',
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          lastGateCheckedAt.value = DateTime.now();
          lastSyncState.value = 'gate_error';
          lastSyncError.value = '$error';
          debugPrint(
            '[QA_LAB][REMOTE_GATE_WATCH_ERROR] ${error.runtimeType}: $error\n$stackTrace',
          );
        },
      );
    _legacyAdminConfigSubscription ??= ConfigRepository.ensure()
        .watchAdminConfigDoc(
        'admin',
        ttl: const Duration(seconds: 20),
      )
        .listen(
        (doc) {
          _applyRemoteGateState(
            qaEnabled: _qaGateEnabled,
            legacyEnabled: doc['qaCollectionEnabled'] == true,
            source: 'legacy_admin_watch',
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          lastGateCheckedAt.value = DateTime.now();
          lastSyncState.value = 'gate_error';
          lastSyncError.value = '$error';
          debugPrint(
            '[QA_LAB][REMOTE_GATE_WATCH_ERROR] ${error.runtimeType}: $error\n$stackTrace',
          );
        },
      );
  }

  void _applyRemoteGateState({
    required bool qaEnabled,
    required bool legacyEnabled,
    required String source,
  }) {
    _qaGateEnabled = qaEnabled;
    _legacyGateEnabled = legacyEnabled;
    final enabled = qaEnabled || legacyEnabled;
    remoteCollectionEnabled.value = enabled;
    lastGateCheckedAt.value = DateTime.now();
    if (enabled) {
      _permissionDeniedUntil = null;
      if (lastSyncState.value == 'disabled_by_admin' ||
          lastSyncState.value == 'permission_denied') {
        lastSyncState.value = 'idle';
        lastSyncError.value = '';
      }
      return;
    }
    _pendingSessionDocument = null;
    _pendingOccurrences.clear();
    lastSyncState.value = 'disabled_by_admin';
    lastSyncReason.value = source;
    lastSyncError.value = '';
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> input) {
    return input.map(
      (key, value) => MapEntry(
        key,
        _sanitizeValue(value),
      ),
    );
  }

  Object? _sanitizeValue(Object? value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is Map) {
      return value.map(
        (key, nested) => MapEntry(
          key.toString(),
          _sanitizeValue(nested),
        ),
      );
    }
    if (value is Iterable) {
      return value.map(_sanitizeValue).toList(growable: false);
    }
    return value.toString();
  }

  String _safeFieldKey(String input) {
    final normalized = input.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    if (normalized.isEmpty) {
      return 'unknown';
    }
    return normalized;
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _qaConfigSubscription?.cancel();
    _legacyAdminConfigSubscription?.cancel();
    super.onClose();
  }
}
