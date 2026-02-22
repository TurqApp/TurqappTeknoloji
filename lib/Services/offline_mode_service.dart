// 📁 lib/Services/offline_mode_service.dart
// 📡 Offline mode detection and queue management
// Works with CurrentUserService for seamless offline experience

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineModeService extends GetxController {
  static final OfflineModeService instance = OfflineModeService._internal();
  OfflineModeService._internal();

  final RxBool isOnline = true.obs;
  final RxList<PendingAction> pendingActions = <PendingAction>[].obs;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  SharedPreferences? _prefs;

  static const String _pendingActionsKey = 'pending_actions';

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPendingActions();
    _startConnectivityListener();
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final wasOffline = !isOnline.value;
      isOnline.value = results.any((result) => result != ConnectivityResult.none);

      // Back online - process pending actions
      if (wasOffline && isOnline.value) {
        _processPendingActions();
      }
    });

    // Check initial connectivity
    Connectivity().checkConnectivity().then((results) {
      isOnline.value = results.any((result) => result != ConnectivityResult.none);
    });
  }

  /// Add action to queue when offline
  Future<void> queueAction(PendingAction action) async {
    pendingActions.add(action);
    await _savePendingActions();
    print('📥 Queued action: ${action.type} (offline)');
  }

  /// Process pending actions when back online
  Future<void> _processPendingActions() async {
    if (pendingActions.isEmpty) return;

    print('🔄 Processing ${pendingActions.length} pending actions...');

    final actionsToProcess = List<PendingAction>.from(pendingActions);
    pendingActions.clear();

    for (final action in actionsToProcess) {
      try {
        await action.execute();
        print('✅ Processed: ${action.type}');
      } catch (e) {
        print('❌ Failed to process ${action.type}: $e');
        // Re-queue failed action
        pendingActions.add(action);
      }
    }

    await _savePendingActions();
  }

  Future<void> _loadPendingActions() async {
    try {
      final json = _prefs?.getString(_pendingActionsKey);
      if (json == null) return;

      final List<dynamic> list = jsonDecode(json);
      pendingActions.value = list
          .map((e) => PendingAction.fromJson(e))
          .toList();

      print('📂 Loaded ${pendingActions.length} pending actions');
    } catch (e) {
      print('❌ Failed to load pending actions: $e');
    }
  }

  Future<void> _savePendingActions() async {
    try {
      final json = jsonEncode(
        pendingActions.map((e) => e.toJson()).toList(),
      );
      await _prefs?.setString(_pendingActionsKey, json);
    } catch (e) {
      print('❌ Failed to save pending actions: $e');
    }
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}

/// Pending action model
class PendingAction {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  PendingAction({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'type': type,
    'data': data,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory PendingAction.fromJson(Map<String, dynamic> json) {
    return PendingAction(
      type: json['type'],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }

  /// Execute the pending action
  Future<void> execute() async {
    switch (type) {
      case 'update_profile':
        await _executeUpdateProfile();
        break;
      case 'like_post':
        await _executeLikePost();
        break;
      case 'follow_user':
        await _executeFollowUser();
        break;
      default:
        print('Unknown pending action type: $type');
    }
  }

  Future<void> _executeUpdateProfile() async {
    final uid = data['uid'] as String?;
    final fields = data['fields'] as Map<String, dynamic>?;
    if (uid == null || fields == null) return;

    final firestore = FirebaseFirestore.instance;
    await firestore.collection('users').doc(uid).update(fields);
  }

  Future<void> _executeLikePost() async {
    final postId = data['postId'] as String?;
    final userId = data['userId'] as String?;
    if (postId == null || userId == null) return;

    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('Posts')
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .set({'timeStamp': FieldValue.serverTimestamp()});
  }

  Future<void> _executeFollowUser() async {
    final targetUid = data['targetUid'] as String?;
    final currentUid = data['currentUid'] as String?;
    if (targetUid == null || currentUid == null) return;

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    batch.set(
      firestore.collection('users').doc(targetUid).collection('Takipciler').doc(currentUid),
      {'timeStamp': FieldValue.serverTimestamp()},
    );
    batch.set(
      firestore.collection('users').doc(currentUid).collection('TakipEdilenler').doc(targetUid),
      {'timeStamp': FieldValue.serverTimestamp()},
    );

    await batch.commit();
  }
}
