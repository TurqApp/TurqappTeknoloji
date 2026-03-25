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
part 'offline_mode_service_runtime_part.dart';
part 'offline_mode_service_models_part.dart';

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
    _handleOnInit();
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
