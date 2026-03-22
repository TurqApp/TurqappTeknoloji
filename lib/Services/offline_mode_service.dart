// 📁 lib/Services/offline_mode_service.dart
// 📡 Offline mode detection and queue management
// Works with CurrentUserService for seamless offline experience

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'offline_mode_service_queue_part.dart';
part 'offline_mode_service_persistence_part.dart';
part 'offline_mode_service_action_part.dart';

class OfflineModeService extends GetxController {
  static final OfflineModeService instance = OfflineModeService._internal();
  OfflineModeService._internal();

  static OfflineModeService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(instance, permanent: true);
  }

  static OfflineModeService? maybeFind() {
    final isRegistered = Get.isRegistered<OfflineModeService>();
    if (!isRegistered) return null;
    return Get.find<OfflineModeService>();
  }

  static const int _maxRetryAttempts = 5;
  static const int _baseRetryDelayMs = 1500;
  static const int _maxRetryDelayMs = 5 * 60 * 1000;

  final RxBool isOnline = true.obs;
  final RxBool isSyncing = false.obs;
  final Rxn<DateTime> lastSyncAt = Rxn<DateTime>();
  final RxInt processedCount = 0.obs;
  final RxInt failedCount = 0.obs;
  final RxList<PendingAction> pendingActions = <PendingAction>[].obs;
  final RxList<PendingAction> deadLetterActions = <PendingAction>[].obs;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<User?>? _authSubscription;
  Timer? _retryTimer;
  SharedPreferences? _prefs;
  bool _isProcessing = false;

  static const String _pendingActionsKeyPrefix = 'pending_actions';
  static const String _deadLetterActionsKeyPrefix =
      'pending_actions_dead_letter';
  static const String _lastSyncAtKeyPrefix = 'pending_actions_last_sync_at';
  static const String _processedCountKeyPrefix =
      'pending_actions_processed_count';
  static const String _failedCountKeyPrefix = 'pending_actions_failed_count';

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _disposeOfflineMode();
    super.onClose();
  }

  String get _activeUid {
    final uid = CurrentUserService.instance.effectiveUserId;
    return uid.isEmpty ? 'guest' : uid;
  }

  String get _pendingActionsKey => '$_pendingActionsKeyPrefix:$_activeUid';
  String get _deadLetterActionsKey =>
      '$_deadLetterActionsKeyPrefix:$_activeUid';
  String get _lastSyncAtKey => '$_lastSyncAtKeyPrefix:$_activeUid';
  String get _processedCountKey => '$_processedCountKeyPrefix:$_activeUid';
  String get _failedCountKey => '$_failedCountKeyPrefix:$_activeUid';
}

/// Pending action model
class PendingAction {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? dedupeKey;
  final int attemptCount;
  final int nextAttemptAtMs;
  final int lastTriedAtMs;
  final String? lastError;

  PendingAction({
    required this.type,
    required this.data,
    DateTime? timestamp,
    this.dedupeKey,
    this.attemptCount = 0,
    this.nextAttemptAtMs = 0,
    this.lastTriedAtMs = 0,
    this.lastError,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type,
        'data': data,
        'timestamp': timestamp.millisecondsSinceEpoch,
        if (dedupeKey != null && dedupeKey!.isNotEmpty) 'dedupeKey': dedupeKey,
        'attemptCount': attemptCount,
        'nextAttemptAtMs': nextAttemptAtMs,
        'lastTriedAtMs': lastTriedAtMs,
        if (lastError != null && lastError!.isNotEmpty) 'lastError': lastError,
      };

  factory PendingAction.fromJson(Map<String, dynamic> json) {
    return PendingAction(
      type: json['type'],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      dedupeKey: (json['dedupeKey'] ?? '').toString().trim().isEmpty
          ? null
          : json['dedupeKey'].toString(),
      attemptCount: _asInt(json['attemptCount']),
      nextAttemptAtMs: _asInt(json['nextAttemptAtMs']),
      lastTriedAtMs: _asInt(json['lastTriedAtMs']),
      lastError: (json['lastError'] ?? '').toString().trim().isEmpty
          ? null
          : json['lastError'].toString(),
    );
  }

  PendingAction copyWith({
    String? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    String? dedupeKey,
    int? attemptCount,
    int? nextAttemptAtMs,
    int? lastTriedAtMs,
    String? lastError,
  }) {
    return PendingAction(
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAtMs: nextAttemptAtMs ?? this.nextAttemptAtMs,
      lastTriedAtMs: lastTriedAtMs ?? this.lastTriedAtMs,
      lastError: lastError ?? this.lastError,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
