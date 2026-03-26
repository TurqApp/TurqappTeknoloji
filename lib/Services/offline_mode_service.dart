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
part 'offline_mode_service_facade_part.dart';
part 'offline_mode_service_fields_part.dart';
part 'offline_mode_service_runtime_part.dart';
part 'offline_mode_service_models_part.dart';

class OfflineModeService extends GetxController {
  static final OfflineModeService instance = OfflineModeService._internal();
  OfflineModeService._internal();

  static OfflineModeService ensure() => _ensureOfflineModeService();

  static OfflineModeService? maybeFind() => _maybeFindOfflineModeService();

  static const int _maxRetryAttempts = 5;
  static const int _baseRetryDelayMs = 1500;
  static const int _maxRetryDelayMs = 5 * 60 * 1000;

  final _state = _OfflineModeServiceState();

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
    _handleOfflineModeServiceInit(this);
  }

  @override
  void onClose() {
    _handleOfflineModeServiceClose(this);
    super.onClose();
  }
}
