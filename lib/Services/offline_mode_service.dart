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
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

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

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPendingActions();
    await _loadDeadLetterActions();
    _loadStats();
    _startConnectivityListener();
    _authSubscription ??= FirebaseAuth.instance.authStateChanges().listen((_) {
      unawaited(_reloadForActiveUser());
    });
  }

  Future<void> _reloadForActiveUser() async {
    pendingActions.clear();
    deadLetterActions.clear();
    processedCount.value = 0;
    failedCount.value = 0;
    lastSyncAt.value = null;
    await _loadPendingActions();
    await _loadDeadLetterActions();
    _loadStats();
  }

  String get _activeUid {
    final uid = CurrentUserService.instance.userId.trim();
    return uid.isEmpty ? 'guest' : uid;
  }

  String get _pendingActionsKey => '$_pendingActionsKeyPrefix:$_activeUid';
  String get _deadLetterActionsKey =>
      '$_deadLetterActionsKeyPrefix:$_activeUid';
  String get _lastSyncAtKey => '$_lastSyncAtKeyPrefix:$_activeUid';
  String get _processedCountKey => '$_processedCountKeyPrefix:$_activeUid';
  String get _failedCountKey => '$_failedCountKeyPrefix:$_activeUid';

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final wasOffline = !isOnline.value;
      isOnline.value =
          results.any((result) => result != ConnectivityResult.none);

      // Back online - process pending actions
      if (wasOffline && isOnline.value) {
        processPendingNow();
      }
    });

    // Check initial connectivity
    Connectivity().checkConnectivity().then((results) async {
      isOnline.value =
          results.any((result) => result != ConnectivityResult.none);
      if (isOnline.value) {
        await processPendingNow();
      }
    });

    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!isOnline.value) return;
      if (pendingActions.isEmpty) return;
      await processPendingNow();
    });
  }

  /// Add action to queue when offline
  Future<void> queueAction(PendingAction action) async {
    final prepared = action.copyWith(
      attemptCount: 0,
      nextAttemptAtMs: 0,
      lastError: null,
      lastTriedAtMs: 0,
    );
    if (action.dedupeKey != null && action.dedupeKey!.isNotEmpty) {
      pendingActions.removeWhere((a) => a.dedupeKey == action.dedupeKey);
      deadLetterActions.removeWhere((a) => a.dedupeKey == action.dedupeKey);
    }
    pendingActions.add(prepared);
    await _savePendingActions();
    await _saveDeadLetterActions();
    print('📥 Queued action: ${action.type} (offline)');
  }

  Future<void> processPendingNow({bool ignoreBackoff = false}) async {
    await _processPendingActions(ignoreBackoff: ignoreBackoff);
  }

  Future<void> retryDeadLetter({int limit = 50}) async {
    if (deadLetterActions.isEmpty) return;
    final take = deadLetterActions.take(limit).toList();
    if (take.isEmpty) return;
    for (final action in take) {
      deadLetterActions.remove(action);
      pendingActions.add(action.copyWith(
        attemptCount: 0,
        nextAttemptAtMs: 0,
        lastError: null,
        lastTriedAtMs: 0,
      ));
    }
    await _savePendingActions();
    await _saveDeadLetterActions();
    await processPendingNow(ignoreBackoff: true);
  }

  Future<void> clearDeadLetter() async {
    deadLetterActions.clear();
    await _saveDeadLetterActions();
  }

  Map<String, dynamic> getQueueStats() {
    return {
      'isOnline': isOnline.value,
      'isSyncing': isSyncing.value,
      'pending': pendingActions.length,
      'deadLetter': deadLetterActions.length,
      'processedCount': processedCount.value,
      'failedCount': failedCount.value,
      'lastSyncAt': lastSyncAt.value?.millisecondsSinceEpoch,
    };
  }

  /// Process pending actions when back online
  Future<void> _processPendingActions({bool ignoreBackoff = false}) async {
    if (_isProcessing) return;
    if (pendingActions.isEmpty) return;
    if (!isOnline.value) return;
    _isProcessing = true;
    isSyncing.value = true;
    try {
      print('🔄 Processing ${pendingActions.length} pending actions...');

      final actionsToProcess = List<PendingAction>.from(pendingActions)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      pendingActions.clear();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      var succeeded = 0;

      for (final action in actionsToProcess) {
        if (!ignoreBackoff &&
            action.nextAttemptAtMs > 0 &&
            action.nextAttemptAtMs > nowMs) {
          pendingActions.add(action);
          continue;
        }

        try {
          await action.execute();
          print('✅ Processed: ${action.type}');
          succeeded++;
          processedCount.value++;
        } catch (e) {
          print('❌ Failed to process ${action.type}: $e');
          failedCount.value++;
          final attempts = action.attemptCount + 1;
          if (attempts >= _maxRetryAttempts) {
            deadLetterActions.add(action.copyWith(
              attemptCount: attempts,
              lastError: e.toString(),
              lastTriedAtMs: nowMs,
              nextAttemptAtMs: 0,
            ));
            continue;
          }
          final backoffMs = _retryDelayMs(attempts);
          pendingActions.add(action.copyWith(
            attemptCount: attempts,
            lastError: e.toString(),
            lastTriedAtMs: nowMs,
            nextAttemptAtMs: nowMs + backoffMs,
          ));
        }
      }

      if (succeeded > 0) {
        lastSyncAt.value = DateTime.now();
      }

      await _savePendingActions();
      await _saveDeadLetterActions();
      await _saveStats();
    } finally {
      isSyncing.value = false;
      _isProcessing = false;
    }
  }

  int _retryDelayMs(int attempt) {
    final factor = 1 << (attempt - 1).clamp(0, 10);
    final delay = _baseRetryDelayMs * factor;
    return delay > _maxRetryDelayMs ? _maxRetryDelayMs : delay;
  }

  void _loadStats() {
    final rawLastSync = _prefs?.getInt(_lastSyncAtKey) ?? 0;
    if (rawLastSync > 0) {
      lastSyncAt.value = DateTime.fromMillisecondsSinceEpoch(rawLastSync);
    }
    processedCount.value = _prefs?.getInt(_processedCountKey) ?? 0;
    failedCount.value = _prefs?.getInt(_failedCountKey) ?? 0;
  }

  Future<void> _saveStats() async {
    final syncMs = lastSyncAt.value?.millisecondsSinceEpoch ?? 0;
    await _prefs?.setInt(_lastSyncAtKey, syncMs);
    await _prefs?.setInt(_processedCountKey, processedCount.value);
    await _prefs?.setInt(_failedCountKey, failedCount.value);
  }

  Future<void> _loadDeadLetterActions() async {
    try {
      final json = _prefs?.getString(_deadLetterActionsKey);
      if (json == null) return;
      final List<dynamic> list = jsonDecode(json);
      deadLetterActions.value =
          list.map((e) => PendingAction.fromJson(e)).toList();
    } catch (e) {
      print('❌ Failed to load dead-letter actions: $e');
    }
  }

  Future<void> _saveDeadLetterActions() async {
    try {
      final json = jsonEncode(
        deadLetterActions.map((e) => e.toJson()).toList(),
      );
      await _prefs?.setString(_deadLetterActionsKey, json);
    } catch (e) {
      print('❌ Failed to save dead-letter actions: $e');
    }
  }

  Future<void> _loadPendingActions() async {
    try {
      final json = _prefs?.getString(_pendingActionsKey);
      if (json == null) return;

      final List<dynamic> list = jsonDecode(json);
      pendingActions.value =
          list.map((e) => PendingAction.fromJson(e)).toList();

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
    _authSubscription?.cancel();
    _retryTimer?.cancel();
    super.onClose();
  }
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

  /// Execute the pending action
  Future<void> execute() async {
    switch (type) {
      case 'update_profile':
        await _executeUpdateProfile();
        break;
      case 'like_post':
        await _executeLikePost();
        break;
      case 'set_like_post':
        await _executeSetLikePost();
        break;
      case 'follow_user':
        await _executeFollowUser();
        break;
      case 'set_save_post':
        await _executeSetSavePost();
        break;
      case 'add_comment_post':
        await _executeAddCommentPost();
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
        .set({'timeStamp': DateTime.now().millisecondsSinceEpoch});
  }

  Future<void> _executeSetLikePost() async {
    final postId = data['postId'] as String?;
    final userId = data['userId'] as String?;
    final shouldLike = data['value'] == true;
    if (postId == null || userId == null) return;

    final firestore = FirebaseFirestore.instance;
    final postRef = firestore.collection('Posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);
    final userLikeRef = firestore
        .collection('users')
        .doc(userId)
        .collection('liked_posts')
        .doc(postId);

    await firestore.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) return;

      final postData = postSnap.data() ?? <String, dynamic>{};
      final stats = (postData['stats'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final currentLikeCount = (stats['likeCount'] as num?)?.toInt() ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      if (shouldLike && !likeSnap.exists) {
        tx.set(likeRef, {'userID': userId, 'timeStamp': nowMs});
        tx.set(userLikeRef, {'postDocID': postId, 'timeStamp': nowMs});
        tx.update(postRef, {'stats.likeCount': currentLikeCount + 1});
      } else if (!shouldLike && likeSnap.exists) {
        tx.delete(likeRef);
        tx.delete(userLikeRef);
        final next = currentLikeCount > 0 ? currentLikeCount - 1 : 0;
        tx.update(postRef, {'stats.likeCount': next});
      }
    });
  }

  Future<void> _executeSetSavePost() async {
    final postId = data['postId'] as String?;
    final userId = data['userId'] as String?;
    final shouldSave = data['value'] == true;
    if (postId == null || userId == null) return;

    final firestore = FirebaseFirestore.instance;
    final postRef = firestore.collection('Posts').doc(postId);
    final saveRef = postRef.collection('saveds').doc(userId);
    final userSaveRef = firestore
        .collection('users')
        .doc(userId)
        .collection('saved_posts')
        .doc(postId);

    await firestore.runTransaction((tx) async {
      final saveSnap = await tx.get(saveRef);
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) return;

      final postData = postSnap.data() ?? <String, dynamic>{};
      final stats = (postData['stats'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final currentSavedCount = (stats['savedCount'] as num?)?.toInt() ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      if (shouldSave && !saveSnap.exists) {
        tx.set(saveRef, {'userID': userId, 'timeStamp': nowMs});
        tx.set(userSaveRef, {'postDocID': postId, 'timeStamp': nowMs});
        tx.update(postRef, {'stats.savedCount': currentSavedCount + 1});
      } else if (!shouldSave && saveSnap.exists) {
        tx.delete(saveRef);
        tx.delete(userSaveRef);
        final next = currentSavedCount > 0 ? currentSavedCount - 1 : 0;
        tx.update(postRef, {'stats.savedCount': next});
      }
    });
  }

  Future<void> _executeAddCommentPost() async {
    final postId = data['postId'] as String?;
    final userId = data['userId'] as String?;
    final text = (data['text'] ?? '').toString();
    if (postId == null || userId == null || text.trim().isEmpty) return;

    final imgs = (data['imgs'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    final videos =
        (data['videos'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    final firestore = FirebaseFirestore.instance;
    final postRef = firestore.collection('Posts').doc(postId);
    final commentIdRaw = (data['clientCommentId'] ?? '').toString().trim();
    final commentRef = commentIdRaw.isNotEmpty
        ? postRef.collection('comments').doc(commentIdRaw)
        : postRef.collection('comments').doc();
    final userCommentRef = firestore
        .collection('users')
        .doc(userId)
        .collection('commented_posts')
        .doc(commentRef.id);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await firestore.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) return;
      final existingComment = await tx.get(commentRef);
      if (existingComment.exists) return;

      final postData = postSnap.data() ?? <String, dynamic>{};
      final stats = (postData['stats'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final currentCommentCount = (stats['commentCount'] as num?)?.toInt() ?? 0;

      tx.set(commentRef, {
        'likes': <String>[],
        'text': text,
        'imgs': imgs,
        'videos': videos,
        'timeStamp': nowMs,
        'userID': userId,
        'docID': commentRef.id,
        'edited': false,
        'editTimestamp': 0,
        'deleted': false,
        'deletedTimeStamp': 0,
        'hasReplies': false,
        'repliesCount': 0,
      });
      tx.set(userCommentRef, {'postDocID': postId, 'timeStamp': nowMs});
      tx.update(postRef, {'stats.commentCount': currentCommentCount + 1});
    });
  }

  Future<void> _executeFollowUser() async {
    final targetUid = data['targetUid'] as String?;
    final currentUid = data['currentUid'] as String?;
    if (targetUid == null || currentUid == null) return;
    await FollowRepository.ensure().createRelationPair(
      currentUid: currentUid,
      otherUid: targetUid,
    );
  }
}
